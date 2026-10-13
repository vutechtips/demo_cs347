"""Assert real WAN encapsulation versus inner LAN traffic, using tcpdump."""
import pathlib
import signal
import subprocess
import time

state = pathlib.Path('/var/lib/cs347-lab')
captures = state / 'captures'
processes = []
try:
    for interface in ('wan0', 'tun0'):
        processes.append(subprocess.Popen([
            'ip', 'netns', 'exec', 'cs347-hq', 'tcpdump', '-U', '-ni',
            interface, '-w', str(captures / (interface + '.pcap')),
        ], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE))
    time.sleep(0.6)
    subprocess.run([
        'ip', 'netns', 'exec', 'cs347-pc1', 'curl', '--noproxy', '*',
        '--cacert', str(state / 'web/cert.pem'), '--max-time', '5',
        '-fsS', 'https://10.10.20.10/',
    ], check=True)
    time.sleep(1.5)
finally:
    for process in processes:
        process.send_signal(signal.SIGINT)
        process.communicate(timeout=5)
        if process.returncode != 0:
            raise RuntimeError('tcpdump did not complete successfully')

def read(interface):
    return subprocess.check_output([
        'tcpdump', '-nn', '-r', str(captures / (interface + '.pcap')),
    ], stderr=subprocess.DEVNULL, text=True)

wan = read('wan0')
tunnel = read('tun0')
assert '198.51.100.11' in wan and '198.51.100.10.1194' in wan, wan
assert '10.20.10.10' not in wan and '10.10.20.10' not in wan, wan
assert '10.20.10.10' in tunnel and '10.10.20.10.443' in tunnel, tunnel
print('[PASS] WAN: outer WAN IPs / UDP1194; tunnel: inner LAN IPs / TCP443.')
print('PCAPs saved locally in /var/lib/cs347-lab/captures (not committed).')
