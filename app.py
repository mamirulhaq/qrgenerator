from flask import Flask, render_template, request, redirect, session, url_for, send_file
from io import BytesIO
import base64
import qrcode
from PIL import Image
import os

app = Flask(__name__)
app.secret_key = 'secret'

USE_LOGO = False

def generate_qr_with_logo(data):
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    qr.add_data(data)
    qr.make(fit=True)

    qr_img = qr.make_image(fill_color="black", back_color="white").convert('RGBA')

    if USE_LOGO:
        logo_path = 'static/logo.png'
        if os.path.exists(logo_path):
            logo = Image.open(logo_path).convert("RGBA")
            qr_width, qr_height = qr_img.size
            factor = 4
            logo_size = (qr_width // factor, qr_height // factor)
            logo = logo.resize(logo_size, Image.LANCZOS)
            pos = ((qr_width - logo.size[0]) // 2, (qr_height - logo.size[1]) // 2)
            qr_img.paste(logo, pos, mask=logo)

    return qr_img

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        data = request.form['data']
        session['qr_data'] = data
        session['just_generated'] = True  # ← penanda bahwa baru saja di-generate
        return redirect(url_for('result'))
    return render_template('index.html')

@app.route('/result')
def result():
    if not session.get('just_generated'):
        return redirect(url_for('index'))  # ← tolak jika tidak dari POST
    session['just_generated'] = False  # ← reset agar tidak bisa refresh terus

    data = session.get('qr_data')
    if not data:
        return redirect(url_for('index'))

    img = generate_qr_with_logo(data)
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
    return render_template('result.html', qr_data=data, qr_img=img_base64)

@app.route('/download')
def download():
    data = session.get('qr_data')
    if not data:
        return redirect(url_for('index'))

    img = generate_qr_with_logo(data)
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)
    return send_file(buffer, mimetype='image/png', as_attachment=True, download_name='qrcode.png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
