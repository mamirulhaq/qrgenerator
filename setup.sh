#!/bin/bash

echo "?? Memulai proses setup..."

# Ambil folder saat ini sebagai base path
APP_DIR=$(pwd)
SERVICE_NAME="qrgenerator"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
USE_LOGO=""

# Tanya apakah user ingin menggunakan logo
while true; do
    read -p "? Do you want to use a logo in the QR Code? (Y/n): " yn
    case $yn in
        [Yy]* ) USE_LOGO="yes"; break;;
        [Nn]* ) USE_LOGO="no"; break;;
        * ) echo "Please answer with Y or n.";;
    esac
done

# Jika ingin menggunakan logo, beri informasi ke user
if [ "$USE_LOGO" == "yes" ]; then
    echo "???  Please place your logo in this folder: $APP_DIR/static/logo.png"
    sleep 2
    sed -i 's/^USE_LOGO = .*/USE_LOGO = True/' app.py
else
    echo "??  QR Code akan dibuat tanpa logo."
    sed -i 's/^USE_LOGO = .*/USE_LOGO = False/' app.py
fi

# Update dan install dependensi sistem
echo "?? Menginstall Zint, Python, dan virtual environment tools..."
sudo apt update
sudo apt install -y zint python3 python3-pip python3-venv

# Membuat virtual environment jika belum ada
if [ ! -d "venv" ]; then
  echo "?? Create virtual environment in $APP_DIR/venv..."
  python3 -m venv venv
fi

# Install dependensi Python dari dalam virtualenv
echo "?? Install dependency Python (Flask, Pillow, qrcode)..."
$APP_DIR/venv/bin/pip install --upgrade pip
$APP_DIR/venv/bin/pip install flask Pillow "qrcode[pil]"

# Set file permission agar dapat dijalankan
chmod +x "$APP_DIR/setup.sh"
chmod +x "$APP_DIR/app.py"

# Buat file systemd service
echo "?? Create systemd service in $SERVICE_FILE..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Barcode Flask App
After=network.target

[Service]
User=root
WorkingDirectory=$APP_DIR
Environment=\"PATH=$APP_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"
ExecStart=$APP_DIR/venv/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd & aktifkan service
echo "?? Reloading systemd daemon..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "? Setup done!"
echo "?? Application running as a service: $SERVICE_NAME"
echo "?? View status with: sudo systemctl status $SERVICE_NAME"
echo "?? View log with: journalctl -u $SERVICE_NAME -f"
