package proxy

import (
	"strings"
	"testing"
)

func TestCredentialValidation(t *testing.T) {
	for _, tc := range []struct {
		name, input, want string
		invalid           bool
	}{
		{name: "no newline", input: "a-token", want: "a-token"},
		{name: "LF", input: "a-token\n", want: "a-token"},
		{name: "CRLF", input: "a-token\r\n", want: "a-token"},
		{name: "preserve spaces", input: " token \n", want: " token "},
		{name: "empty", invalid: true},
		{name: "empty line", input: "\n", invalid: true},
		{name: "multiple lines", input: "first\nsecond", invalid: true},
		{name: "two trailing lines", input: "token\n\n", invalid: true},
		{name: "bare CR", input: "token\r", invalid: true},
		{name: "header injection", input: "token\r\nInjected: yes", invalid: true},
		{name: "oversize", input: strings.Repeat("x", (64<<10)+1), invalid: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			file := writeFile(t, t.TempDir(), "credential", tc.input)
			got, err := readCredential(file)
			if tc.invalid {
				if err == nil {
					t.Fatal("accepted invalid credential")
				}
			} else if err != nil || got != tc.want {
				t.Fatalf("got %q, %v; want %q", got, err, tc.want)
			}
		})
	}
}
