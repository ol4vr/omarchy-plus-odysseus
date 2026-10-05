#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='odysseus-test-') as directory:
    folder = Path(directory)
    record = folder / 'calls'
    for command in ('pkexec', 'xdg-open', 'notify-send'):
        f = folder / command
        f.write_text('#!/bin/bash\nprintf "%s" "' + command + '" >> "$CALLS"\nprintf " <%s>" "$@" >> "$CALLS"\nprintf "\\n" >> "$CALLS"\n' + ('exit "${AUTH_RESULT:-0}"\n' if command == 'pkexec' else 'exit 0\n'))
        f.chmod(0o755)
    env = dict(os.environ, PATH=str(folder) + ':' + os.environ['PATH'], CALLS=str(record), XDG_STATE_HOME=str(folder/'state'))
    def run(action, result=0):
        record.write_text('')
        proc = subprocess.run(['bash', str(root / 'scripts/control'), action], env=dict(env, AUTH_RESULT=str(result)), capture_output=True)
        return proc.returncode, record.read_text()
    rc, calls = run('open')
    assert rc == 0 and 'pkexec </usr/bin/systemctl> <start> <omarchy-plus-odysseus.service>' in calls
    assert 'xdg-open <http://localhost:7000>' in calls
    rc, calls = run('open', 1)
    assert rc == 1 and 'xdg-open' not in calls
    rc, calls = run('stop')
    assert rc == 0 and '<stop> <omarchy-plus-odysseus.service>' in calls and 'xdg-open' not in calls
    rc, calls = run('auto-open-off')
    assert rc == 0 and calls == ''
    rc, calls = run('start')
    assert rc == 0 and '<start>' in calls and 'xdg-open' not in calls
    rc, calls = run('auto-open-on')
    assert rc == 0 and calls == ''
    rc, calls = run('start')
    assert rc == 0 and 'xdg-open <http://localhost:7000>' in calls
    rc, calls = run('invalid')
    assert rc == 2 and calls == ''
print('Open, Stop, cancelled authentication and invalid action: PASS')
