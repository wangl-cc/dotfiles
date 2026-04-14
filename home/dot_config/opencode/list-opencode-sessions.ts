#!/usr/bin/env bun
/**
 * List all OpenCode sessions across all projects using the SDK API
 * This uses client.experimental.session.list() to get ALL sessions globally
 */

import { createOpencodeClient } from '@opencode-ai/sdk/v2';

interface Session {
  id?: string;
  title?: string;
  project?: { id?: string; name?: string; directory?: string };
  workspace?: { id?: string; name?: string };
  updatedAt?: string;
  createdAt?: string;
  archived?: boolean;
}

async function listAllSessions(): Promise<void> {
  console.log('🔍 Fetching all OpenCode sessions...\n');

  // OpenCode server runs on localhost:4096 by default
  // You can change this if your server runs on a different port
  const OPCODE_SERVER_URL = process.env.OPENCODE_URL || 'http://localhost:4096';

  const client = createOpencodeClient({
    baseUrl: OPCODE_SERVER_URL,
  });

  try {
    // This lists ALL sessions across ALL projects (global)
    const result = await client.experimental.session.list({
      limit: 100,  // Adjust as needed
      archived: false,  // Set to true to include archived sessions
    });

    const sessions = (result.data?.sessions || result.data || []) as Session[];

    if (sessions.length === 0) {
      console.log('No sessions found.');
      return;
    }

    console.log(`Found ${sessions.length} session(s):\n`);
    console.log('='.repeat(100));

    for (const session of sessions) {
      const sessionId = session.id || 'unknown';
      const title = session.title || 'Untitled';
      const projectName = session.project?.name || session.project?.directory || 'Unknown project';
      const workspaceName = session.workspace?.name || 'default';
      const updatedAt = session.updatedAt
        ? new Date(session.updatedAt).toLocaleString()
        : 'Unknown';

      console.log(`📌 ${title}`);
      console.log(`   ID:        ${sessionId}`);
      console.log(`   Project:   ${projectName}`);
      console.log(`   Workspace: ${workspaceName}`);
      console.log(`   Updated:   ${updatedAt}`);
      console.log('-'.repeat(100));
    }

  } catch (error) {
    console.error('❌ Error fetching sessions:', error);
    process.exit(1);
  }
}

listAllSessions();
