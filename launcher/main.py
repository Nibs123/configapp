#!/usr/bin/env python3
"""Field Configurator launcher UI.

Fullscreen Tkinter launcher with touch/mouse support.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from tkinter import BOTH, END, LEFT, RIGHT, VERTICAL, Y, Button, Frame, Label, Listbox, Scrollbar, Tk, Toplevel, filedialog, messagebox

import yaml

ROOT = Path(__file__).resolve().parent
REPO_ROOT = ROOT.parent
DEFAULT_CONFIG = ROOT / "config.yaml"
FIRMWARE_INDEX = REPO_ROOT / "firmware-cache" / "firmware_index.json"


@dataclass
class ToolConfig:
    name: str
    command: list[str]


class LauncherApp:
    def __init__(self, config_path: Path = DEFAULT_CONFIG):
        with config_path.open("r", encoding="utf-8") as handle:
            self.config = yaml.safe_load(handle)

        self.root = Tk()
        self.root.title("Field Configurator")
        self.root.configure(bg="#101522")
        self.root.attributes("-fullscreen", bool(self.config["ui"].get("fullscreen", True)))
        self.root.bind("<Escape>", self._exit_fullscreen)

        self.tools = self._load_tools()
        self.selection = 0

        self.header = Label(
            self.root,
            text=self.config["ui"].get("title", "Field Configurator"),
            fg="white",
            bg="#101522",
            font=("DejaVu Sans", 28, "bold"),
            pady=20,
        )
        self.header.pack()

        self.button_frame = Frame(self.root, bg="#101522")
        self.button_frame.pack(fill=BOTH, expand=True, padx=50, pady=30)

        self.buttons: list[Button] = []
        for idx, tool in enumerate(self.tools):
            btn = Button(
                self.button_frame,
                text=tool.name,
                command=lambda i=idx: self.launch_tool(i),
                font=("DejaVu Sans", 24, "bold"),
                height=3,
                bg="#1f4b99",
                fg="white",
                activebackground="#2f6bcb",
                relief="raised",
                bd=3,
            )
            btn.pack(fill=BOTH, expand=True, pady=12)
            self.buttons.append(btn)

        fw_btn = Button(
            self.root,
            text="Offline Firmware Manager",
            command=self.open_firmware_manager,
            font=("DejaVu Sans", 18, "bold"),
            bg="#2d7d46",
            fg="white",
            activebackground="#3a9c58",
            padx=20,
            pady=12,
        )
        fw_btn.pack(pady=(0, 20))

        self.status = Label(
            self.root,
            text="Use touch/click to launch. Mouse wheel changes selected tool.",
            fg="#c2cbe0",
            bg="#101522",
            font=("DejaVu Sans", 14),
            pady=10,
        )
        self.status.pack()

        self.root.bind("<MouseWheel>", self.on_mouse_wheel)
        self.root.bind("<Button-4>", lambda _: self.change_selection(-1))
        self.root.bind("<Button-5>", lambda _: self.change_selection(1))
        self.root.bind("<Return>", lambda _: self.launch_tool(self.selection))
        self.root.bind("<KP_Enter>", lambda _: self.launch_tool(self.selection))
        self.root.bind("<Up>", lambda _: self.change_selection(-1))
        self.root.bind("<Down>", lambda _: self.change_selection(1))
        self.render_selection()

    def _load_tools(self) -> list[ToolConfig]:
        tools = []
        for tool in self.config["tools"]:
            tools.append(ToolConfig(name=tool["name"], command=tool["command"]))
        return tools

    def _exit_fullscreen(self, _event=None):
        self.root.attributes("-fullscreen", False)

    def on_mouse_wheel(self, event):
        delta = -1 if event.delta > 0 else 1
        self.change_selection(delta)

    def change_selection(self, delta: int):
        self.selection = (self.selection + delta) % len(self.buttons)
        self.render_selection()

    def render_selection(self):
        for i, btn in enumerate(self.buttons):
            if i == self.selection:
                btn.configure(bg="#3f8cff")
            else:
                btn.configure(bg="#1f4b99")

    def launch_tool(self, index: int):
        tool = self.tools[index]
        self.status.configure(text=f"Launching {tool.name}...")
        self.root.update_idletasks()

        env = os.environ.copy()
        env["REPO_ROOT"] = str(REPO_ROOT)
        try:
            subprocess.run(tool.command, check=True, env=env)
            self.status.configure(text=f"{tool.name} closed. Select another tool.")
        except subprocess.CalledProcessError as exc:
            self.status.configure(text=f"{tool.name} failed: {exc}")
            messagebox.showerror("Launch failed", f"Could not launch {tool.name}.\n{exc}")

    def open_firmware_manager(self):
        manager = Toplevel(self.root)
        manager.title("Offline Firmware Manager")
        manager.attributes("-fullscreen", bool(self.config["ui"].get("fullscreen", True)))
        manager.configure(bg="#151922")

        title = Label(
            manager,
            text="Cached Firmware",
            fg="white",
            bg="#151922",
            font=("DejaVu Sans", 24, "bold"),
            pady=15,
        )
        title.pack()

        body = Frame(manager, bg="#151922")
        body.pack(fill=BOTH, expand=True, padx=24, pady=20)

        scrollbar = Scrollbar(body, orient=VERTICAL)
        scrollbar.pack(side=RIGHT, fill=Y)

        listing = Listbox(body, font=("DejaVu Sans", 14), yscrollcommand=scrollbar.set)
        listing.pack(side=LEFT, fill=BOTH, expand=True)
        scrollbar.config(command=listing.yview)

        def refresh_listing():
            listing.delete(0, END)
            if not FIRMWARE_INDEX.exists():
                listing.insert(END, "No index yet. Run firmware_indexer.py first.")
                return
            with FIRMWARE_INDEX.open("r", encoding="utf-8") as handle:
                index = json.load(handle)
            for stack, targets in index.items():
                listing.insert(END, f"[{stack}]")
                for target, versions in targets.items():
                    for version, files in versions.items():
                        listing.insert(END, f"  {target} / {version} ({len(files)} files)")

        def import_firmware():
            selected = filedialog.askopenfilenames(
                parent=manager,
                title="Select firmware files to import",
                initialdir="/media",
                filetypes=[("Firmware", "*.hex *.bin"), ("All files", "*.*")],
            )
            if not selected:
                return

            target_stack = self.config["firmware"].get("default_stack", "betaflight")
            target_name = self.config["firmware"].get("default_target", "unknown_target")
            target_version = self.config["firmware"].get("default_version", "manual")
            destination = REPO_ROOT / "firmware-cache" / target_stack / target_name / target_version
            destination.mkdir(parents=True, exist_ok=True)

            for src in selected:
                shutil.copy2(src, destination / Path(src).name)

            subprocess.run([sys.executable, str(REPO_ROOT / "tools" / "firmware_indexer.py")], check=False)
            refresh_listing()
            messagebox.showinfo("Import complete", f"Imported {len(selected)} file(s) into {destination}")

        controls = Frame(manager, bg="#151922")
        controls.pack(pady=10)

        Button(controls, text="Import from USB", command=import_firmware, font=("DejaVu Sans", 16), padx=20, pady=10).pack(side=LEFT, padx=10)
        Button(controls, text="Refresh", command=refresh_listing, font=("DejaVu Sans", 16), padx=20, pady=10).pack(side=LEFT, padx=10)
        Button(controls, text="Close", command=manager.destroy, font=("DejaVu Sans", 16), padx=20, pady=10).pack(side=LEFT, padx=10)

        manager.bind("<Escape>", lambda _e: manager.destroy())
        refresh_listing()

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    app = LauncherApp()
    app.run()
