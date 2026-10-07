#!/usr/bin/env python3
"""Simulator panel: live MJPEG stream of the booted simulator plus taps, swipes, text and buttons.

Runs on the demo Mac next to the simulator (http://127.0.0.1:8080), reached through an SSH tunnel.
Video comes from `idb video-stream --format mjpeg`, input goes through `idb ui ...`.
"""
import json
import os
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

UDID = sys.argv[1] if len(sys.argv) > 1 else open(os.path.expanduser("~/demo-udid")).read().strip()
PORT = 8080
IDB = ["idb"]


def idb(*args):
    return subprocess.run(IDB + list(args) + ["--udid", UDID], capture_output=True, text=True, timeout=30)


def screen_points():
    try:
        out = subprocess.run(IDB + ["describe", "--json", "--udid", UDID], capture_output=True, text=True, timeout=30).stdout
        dims = json.loads(out)["screen_dimensions"]
        return dims["width_points"], dims["height_points"]
    except Exception:
        return 440, 956


POINTS = screen_points()


class Frames:
    def __init__(self):
        self.cond = threading.Condition()
        self.frame = None
        self.seq = 0

    def run(self):
        while True:
            proc = subprocess.Popen(IDB + ["video-stream", "--udid", UDID, "--format", "mjpeg", "--fps", "30",
                                           "--compression-quality", "0.6", "--scale-factor", "0.5"],
                                    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            buf = b""
            while True:
                chunk = proc.stdout.read(65536)
                if not chunk:
                    break
                buf += chunk
                while True:
                    start = buf.find(b"\xff\xd8")
                    end = buf.find(b"\xff\xd9", start + 2) if start >= 0 else -1
                    if start < 0 or end < 0:
                        break
                    with self.cond:
                        self.frame = buf[start:end + 2]
                        self.seq += 1
                        self.cond.notify_all()
                    buf = buf[end + 2:]
            time.sleep(1)


frames = Frames()
threading.Thread(target=frames.run, daemon=True).start()

PAGE = r"""<!doctype html><html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Simulator</title>
<style>
:root{--bg:#0b0b0d;--panel:#18181b;--text:#f2f2f2;--muted:#8e8e93;--accent:#e83030}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px -apple-system,system-ui,sans-serif;display:flex;gap:20px;justify-content:center;padding:16px;height:100vh}
#phone{position:relative;height:calc(100vh - 32px);aspect-ratio:POINTS_W/POINTS_H;border-radius:48px;overflow:hidden;background:#000;box-shadow:0 0 0 10px #1c1c1f,0 0 0 12px #333,0 30px 80px #000;cursor:pointer;user-select:none;touch-action:none}
#phone img{width:100%;height:100%;display:block;pointer-events:none}
#side{width:220px;display:flex;flex-direction:column;gap:8px}
button{background:var(--panel);color:var(--text);border:1px solid #2c2c30;border-radius:12px;padding:10px;font:inherit;cursor:pointer;text-align:left}
button:hover{border-color:#444}button.red{background:var(--accent);border-color:var(--accent)}
input{background:var(--panel);color:var(--text);border:1px solid #2c2c30;border-radius:12px;padding:10px;font:inherit;width:100%}
h3{margin:10px 0 2px;font-size:12px;color:var(--muted);text-transform:uppercase;letter-spacing:.05em}
#status{color:var(--muted);font-size:12px;min-height:16px}
.row{display:flex;gap:6px}.row button{flex:1;text-align:center}
</style></head><body>
<div id="phone"><img id="screen" src="/stream"></div>
<div id="side">
<h3>Кнопки</h3>
<button onclick="act('home')">⌂ Домой</button>
<button onclick="act('switcher')">▤ Переключатель приложений</button>
<button onclick="act('lock')">⏻ Блокировка</button>
<h3>Face ID</h3>
<div class="row"><button onclick="act('faceid_match')">✅ Лицо</button><button onclick="act('faceid_nomatch')">❌ Чужое</button></div>
<h3>Текст</h3>
<input id="text" placeholder="Напиши и нажми Enter">
<div class="row"><button onclick="act('enter')">↵ Enter</button><button onclick="act('backspace')">⌫</button></div>
<h3>Ссылка</h3>
<input id="url" placeholder="tg://resolve?domain=…">
<h3>Прочее</h3>
<button onclick="location.href='/screenshot'">📸 Скриншот</button>
<button onclick="act('relaunch')">↻ Перезапустить exteraGram</button>
<div id="status">Клик — тап, перетаскивание — свайп, долгое нажатие — удержание.</div>
</div>
<script>
const PW=POINTS_W, PH=POINTS_H, phone=document.getElementById('phone'), status=document.getElementById('status');
function pt(e){const r=phone.getBoundingClientRect();return [Math.round((e.clientX-r.left)/r.width*PW),Math.round((e.clientY-r.top)/r.height*PH)]}
async function post(path,body){status.textContent='…';const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body||{})});status.textContent=r.ok?'ok':'ошибка'}
function act(name){post('/action',{name})}
let down=null;
phone.addEventListener('pointerdown',e=>{down={p:pt(e),t:Date.now()};phone.setPointerCapture(e.pointerId)});
phone.addEventListener('pointerup',e=>{if(!down)return;const p=pt(e),dt=(Date.now()-down.t)/1000,dx=p[0]-down.p[0],dy=p[1]-down.p[1];
 if(Math.hypot(dx,dy)<8){post('/tap',{x:p[0],y:p[1],duration:Math.max(0.15,dt)})}else{post('/swipe',{x1:down.p[0],y1:down.p[1],x2:p[0],y2:p[1],duration:Math.min(1.5,Math.max(0.15,dt))})}down=null});
document.getElementById('text').addEventListener('keydown',e=>{if(e.key==='Enter'){post('/text',{text:e.target.value});e.target.value=''}});
document.getElementById('url').addEventListener('keydown',e=>{if(e.key==='Enter'){post('/openurl',{url:e.target.value})}});
document.getElementById('screen').onerror=()=>setTimeout(()=>{document.getElementById('screen').src='/stream?'+Date.now()},1000);
</script></body></html>"""


def run_action(name):
    if name == "home":
        idb("ui", "button", "HOME")
    elif name == "lock":
        idb("ui", "button", "LOCK")
    elif name == "switcher":
        idb("ui", "button", "HOME")
        time.sleep(0.08)
        idb("ui", "button", "HOME")
    elif name == "enter":
        idb("ui", "key", "40")
    elif name == "backspace":
        idb("ui", "key", "42")
    elif name in ("faceid_match", "faceid_nomatch"):
        event = "match" if name == "faceid_match" else "nomatch"
        subprocess.run(["xcrun", "simctl", "spawn", UDID, "notifyutil", "-p", "com.apple.BiometricKit_Sim.pearl." + event])
    elif name == "relaunch":
        subprocess.run(["xcrun", "simctl", "terminate", UDID, "ph.telegra.Telegraph"])
        subprocess.run(["xcrun", "simctl", "launch", UDID, "ph.telegra.Telegraph"])


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/":
            body = PAGE.replace("POINTS_W", str(POINTS[0])).replace("POINTS_H", str(POINTS[1])).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)
        elif path == "/stream":
            self.send_response(200)
            self.send_header("Content-Type", "multipart/x-mixed-replace; boundary=frame")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            seq = -1
            try:
                while True:
                    with frames.cond:
                        frames.cond.wait_for(lambda: frames.seq != seq, timeout=5)
                        frame, seq = frames.frame, frames.seq
                    if frame is None:
                        continue
                    self.wfile.write(b"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %d\r\n\r\n" % len(frame))
                    self.wfile.write(frame + b"\r\n")
            except (BrokenPipeError, ConnectionResetError):
                pass
        elif path == "/screenshot":
            out = "/tmp/sim-panel-shot.png"
            subprocess.run(["xcrun", "simctl", "io", UDID, "screenshot", out], capture_output=True)
            data = open(out, "rb").read()
            self.send_response(200)
            self.send_header("Content-Type", "image/png")
            self.send_header("Content-Disposition", "attachment; filename=simulator.png")
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_error(404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        data = json.loads(self.rfile.read(length) or b"{}")
        path = urlparse(self.path).path
        if path == "/tap":
            idb("ui", "tap", str(data["x"]), str(data["y"]), "--duration", "%.2f" % data.get("duration", 0.15))
        elif path == "/swipe":
            idb("ui", "swipe", str(data["x1"]), str(data["y1"]), str(data["x2"]), str(data["y2"]), "--duration", "%.2f" % data.get("duration", 0.3))
        elif path == "/text":
            idb("ui", "text", data.get("text", ""))
        elif path == "/openurl":
            subprocess.run(["xcrun", "simctl", "openurl", UDID, data.get("url", "")])
        elif path == "/action":
            run_action(data.get("name", ""))
        else:
            self.send_error(404)
            return
        self.send_response(204)
        self.end_headers()


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
