package main

import (
	"io"
	"log"
	"net/http"
	"net/http/cgi"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// Exercise an actual smart-HTTP push and clone when Git is available. The
// container builder can run the remaining protocol tests without installing Git.
func TestGitPushAndCloneWithoutClientCredentials(t *testing.T) {
	git, err := exec.LookPath("git")
	if err != nil {
		t.Skip("Git is not installed")
	}
	env := make([]string, 0, len(os.Environ()))
	for _, item := range os.Environ() {
		if !strings.HasPrefix(item, "GIT_") {
			env = append(env, item)
		}
	}
	env = append(env, "GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null", "GIT_TERMINAL_PROMPT=0")
	gitRun := func(args ...string) string {
		t.Helper()
		cmd := exec.Command(git, args...)
		cmd.Env = env
		output, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, output)
		}
		return strings.TrimSpace(string(output))
	}
	backend := filepath.Join(gitRun("--exec-path"), "git-http-backend")
	if _, err := os.Stat(backend); err != nil {
		t.Skip("Git HTTP backend is not installed")
	}
	dir := t.TempDir()
	bare := filepath.Join(dir, "repo.git")
	local := filepath.Join(dir, "local")
	clone := filepath.Join(dir, "clone")
	gitRun("init", "--bare", "--initial-branch=main", bare)
	gitRun("init", "--initial-branch=main", local)
	writeFile(t, local, "paper.txt", "a local Git protocol fixture\n")
	gitRun("-C", local, "add", "paper.txt")
	gitRun("-C", local, "-c", "user.name=Proxy Test", "-c", "user.email=proxy@example.invalid", "commit", "-m", "initial")

	cgiBackend := &cgi.Handler{
		Path:   backend,
		Root:   "/",
		Env:    []string{"GIT_PROJECT_ROOT=" + dir, "GIT_HTTP_EXPORT_ALL=1", "REMOTE_USER=git", "GIT_CONFIG_NOSYSTEM=1", "GIT_CONFIG_GLOBAL=/dev/null"},
		Stderr: io.Discard,
	}
	upstream := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, password, ok := r.BasicAuth()
		if !ok || user != "git" || password != "dummy-token" {
			http.Error(w, "authentication required", http.StatusUnauthorized)
			return
		}
		cgiBackend.ServeHTTP(w, r)
	}))
	defer upstream.Close()
	writeFile(t, dir, "credential", "dummy-token")
	s, err := compileService(serviceConfig{Upstream: upstream.URL, Auth: authConfig{Type: "basic", Username: "git", Credential: "credential"}}, dir)
	if err != nil {
		t.Fatal(err)
	}
	proxy := httptest.NewServer(newHandler(map[string]service{"overleaf": s}, upstream.Client().Transport, 10*time.Second, log.New(io.Discard, "", 0)))
	defer proxy.Close()
	remote := proxy.URL + "/overleaf/repo.git"
	gitRun("-C", local, "push", remote, "main")
	gitRun("clone", "--branch=main", remote, clone)
	if gitRun("-C", local, "rev-parse", "HEAD") != gitRun("-C", clone, "rev-parse", "HEAD") {
		t.Fatal("cloned revision differs from pushed revision")
	}
	data, err := os.ReadFile(filepath.Join(clone, "paper.txt"))
	if err != nil || string(data) != "a local Git protocol fixture\n" {
		t.Fatal("Git transfer changed repository contents")
	}
}
