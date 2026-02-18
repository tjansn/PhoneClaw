# Remote access to the phone

Run the install from your computer by opening a shell on the phone over **SSH** or **Tailscale**. Use a real keyboard and avoid typing long commands in Termux on the device.

**Security:** You are giving your computer access to the phone. Use a strong password or SSH keys. For SSH over Wi‑Fi, keep the phone on your local network. For Tailscale, the connection is encrypted and does not require opening ports.

---

## Option A: SSH over Wi‑Fi

### On the phone (Termux)

Do this once. You can do it in Termux on the device or over an existing SSH session.

1. Install OpenSSH and start the server:

   ```bash
   pkg update && pkg upgrade -y
   pkg install -y openssh
   sshd
   ```

2. Set a password for the Termux user (required for SSH login):

   ```bash
   passwd
   ```

3. Get the phone’s IP and your username (phone and computer must be on the same Wi‑Fi):

   ```bash
   echo "ssh -p 8022 $(whoami)@$(ip -4 -o addr show wlan0 | awk '{print $4}' | cut -d/ -f1)"
   ```

   Copy the printed `ssh` command.

Termux’s sshd listens on **port 8022** (not 22). To keep sshd running after you close Termux, run it inside tmux: `tmux new -s ssh` then `sshd`; detach with `Ctrl+b` then `d`.

### From your computer

```bash
ssh -p 8022 <termux_username>@<phone_ip>
```

Use the command you printed above, or substitute `<termux_username>` (e.g. `u0_a123`, from `whoami` on the phone) and `<phone_ip>` (e.g. `192.168.1.10`).

**SSH keys (recommended):** On your computer run `ssh-keygen -t ed25519`, then `ssh-copy-id -p 8022 <termux_username>@<phone_ip>` so you can log in without typing the password.

---

## Option B: Tailscale

With [Tailscale](https://tailscale.com) on both the phone and your computer, you can SSH to the phone without opening port 8022 or being on the same Wi‑Fi.

1. On the phone: install Termux, then install the Tailscale app from the [Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn) or [F-Droid](https://f-droid.org/en/packages/com.tailscale.ipn/). Log in and connect.
2. In Termux, install OpenSSH and start sshd (see Option A). Install the Tailscale CLI in Termux if you want to see the phone’s Tailscale IP: `pkg install -y tailscale` (if available) or use the Tailscale admin console to find the device’s name or IP.
3. On your computer: install and log into Tailscale. From your computer:

   ```bash
   ssh -p 8022 <termux_username>@<phone_tailscale_ip_or_name>
   ```

   Use the phone’s Tailscale IP or MagicDNS name (e.g. `myphone.tail12345.ts.net`) and the Termux username.

---

## Access the Dashboard from your computer (safer default)

After you SSH into the phone, keep OpenClaw bound to localhost and forward the Dashboard port over SSH:

```bash
ssh -L 18789:127.0.0.1:18789 -p 8022 <termux_username>@<phone_ip_or_tailscale_name>
```

Then open `http://localhost:18789` on your computer.

---

## Next step

Once you have a shell on the phone (via SSH or Tailscale), follow the [README](../README.md): copy the setup to the phone, then run `./setup_claw.sh`, `openclaw onboard`, and `./scripts/start_claw.sh` from that session.
