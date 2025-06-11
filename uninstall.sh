#!/bin/bash

SERVICE_NAME="qrgenerator"
APP_DIR=$(pwd)
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

echo "🧹 Memulai proses uninstall (Uninstallation process started)..."

# Hentikan dan nonaktifkan service
echo "🛑 Menghentikan service: $SERVICE_NAME"
sudo systemctl stop "$SERVICE_NAME"
sudo systemctl disable "$SERVICE_NAME"

# Hapus file systemd
if [ -f "$SERVICE_FILE" ]; then
    echo "🗑️ Menghapus file systemd service: $SERVICE_FILE"
    sudo rm "$SERVICE_FILE"
fi

# Reload systemd daemon
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Hapus virtual environment
if [ -d "$APP_DIR/venv" ]; then
    echo "🧹 Menghapus virtual environment: $APP_DIR/venv"
    rm -rf "$APP_DIR/venv"
fi

# Tanyakan apakah user ingin menghapus semua file proyek
read -p "❓ Apakah Anda juga ingin menghapus seluruh folder proyek ini ($APP_DIR)? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    cd ..
    echo "🗑️ Menghapus folder proyek: $APP_DIR"
    rm -rf "$APP_DIR"
    echo "✅ Proyek telah dihapus."
else
    echo "⚠️  Folder proyek tidak dihapus. Anda bisa menghapusnya secara manual jika perlu."
fi

echo "✅ Uninstall selesai."
