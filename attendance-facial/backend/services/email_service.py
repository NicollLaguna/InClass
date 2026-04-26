import resend
from config import settings

resend.api_key = settings.RESEND_API_KEY

def _send(to: str, subject: str, html: str):
    try:
        resend.Emails.send({
            "from": settings.EMAIL_FROM,
            "to": to,
            "subject": subject,
            "html": html
        })
    except Exception as e:
        print(f"⚠️ Error enviando email: {e}")

def _base_template(content: str) -> str:
    return f"""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#f0f4f8;padding:20px">
      <div style="background:#1F3864;padding:24px;border-radius:12px 12px 0 0;text-align:center">
        <h1 style="color:white;margin:0;font-size:24px">🎓 InClass</h1>
        <p style="color:#a0b4c8;margin:4px 0 0">Control de Asistencia Facial</p>
      </div>
      <div style="background:white;padding:32px;border-radius:0 0 12px 12px">
        {content}
      </div>
      <p style="text-align:center;color:#6B7280;font-size:12px;margin-top:16px">
        Este es un mensaje automático, no responder.
      </p>
    </div>
    """

# ── Docente ────────────────────────────────────────────

def send_docente_bienvenida(email: str, nombre: str):
    content = f"""
    <h2 style="color:#1F3864">¡Bienvenido, {nombre}!</h2>
    <p>Tu cuenta como docente ha sido creada exitosamente.</p>
    <div style="background:#f0f4f8;padding:16px;border-radius:8px;margin:16px 0">
      <p style="margin:0"><b>Email:</b> {email}</p>
    </div>
    <p style="color:#E74C3C;font-weight:bold">
      ⚠️ Recuerda: tus datos de registro no pueden modificarse.
    </p>
    <p>Ya puedes crear tus cursos y gestionar la asistencia de tus estudiantes.</p>
    """
    _send(email, "Bienvenido a InClass 🎓", _base_template(content))

def send_docente_sesion_resumen(email: str, nombre: str, curso: str, 
                                 fecha: str, total: int, asistentes: list):
    filas = "".join([
        f"<tr><td style='padding:8px;border-bottom:1px solid #eee'>{a['nombre']}</td>"
        f"<td style='padding:8px;border-bottom:1px solid #eee'>{a['codigo']}</td>"
        f"<td style='padding:8px;border-bottom:1px solid #eee'>{a['hora']}</td></tr>"
        for a in asistentes
    ])
    content = f"""
    <h2 style="color:#1F3864">Resumen de sesión</h2>
    <p>Hola <b>{nombre}</b>, aquí el resumen de la clase de hoy.</p>
    <div style="background:#f0f4f8;padding:16px;border-radius:8px;margin:16px 0">
      <p style="margin:4px 0"><b>Curso:</b> {curso}</p>
      <p style="margin:4px 0"><b>Fecha:</b> {fecha}</p>
      <p style="margin:4px 0"><b>Total asistentes:</b> {total}</p>
    </div>
    <table style="width:100%;border-collapse:collapse">
      <tr style="background:#1F3864;color:white">
        <th style="padding:8px;text-align:left">Nombre</th>
        <th style="padding:8px;text-align:left">Código</th>
        <th style="padding:8px;text-align:left">Hora</th>
      </tr>
      {filas}
    </table>
    """
    _send(email, f"Resumen sesión - {curso} 📋", _base_template(content))

# ── Estudiante ─────────────────────────────────────────

def send_estudiante_bienvenida(email: str, nombre: str, codigo: str):
    content = f"""
    <h2 style="color:#1F3864">¡Bienvenido, {nombre}!</h2>
    <p>Tu cuenta como estudiante ha sido creada exitosamente.</p>
    <div style="background:#f0f4f8;padding:16px;border-radius:8px;margin:16px 0">
      <p style="margin:4px 0"><b>Nombre:</b> {nombre}</p>
      <p style="margin:4px 0"><b>Código:</b> {codigo}</p>
      <p style="margin:4px 0"><b>Email:</b> {email}</p>
    </div>
    <p style="color:#E74C3C;font-weight:bold">
      ⚠️ Recuerda: tus datos y foto de registro no pueden modificarse.
      Verifica que todo sea correcto.
    </p>
    <p>Ya puedes solicitar matrícula en tus cursos.</p>
    """
    _send(email, "Bienvenido a InClass 🎓", _base_template(content))

def send_estudiante_matricula_aprobada(email: str, nombre: str, curso: str):
    content = f"""
    <h2 style="color:#2ECC71">¡Matrícula aprobada! ✅</h2>
    <p>Hola <b>{nombre}</b>, tu solicitud fue aprobada.</p>
    <div style="background:#f0f4f8;padding:16px;border-radius:8px;margin:16px 0">
      <p style="margin:0"><b>Curso:</b> {curso}</p>
    </div>
    <p>Ya puedes registrar tu asistencia cuando el docente habilite la sesión.</p>
    """
    _send(email, f"Matrícula aprobada - {curso} ✅", _base_template(content))

def send_estudiante_matricula_rechazada(email: str, nombre: str, curso: str):
    content = f"""
    <h2 style="color:#E74C3C">Matrícula rechazada ❌</h2>
    <p>Hola <b>{nombre}</b>, tu solicitud para <b>{curso}</b> fue rechazada.</p>
    <p>Contacta a tu docente para más información.</p>
    """
    _send(email, f"Matrícula rechazada - {curso}", _base_template(content))

def send_estudiante_asistencia(email: str, nombre: str, curso: str,
                                docente: str, fecha: str, hora: str, 
                                confianza: float):
    content = f"""
    <h2 style="color:#2ECC71">Asistencia registrada ✅</h2>
    <p>Hola <b>{nombre}</b>, tu asistencia fue registrada exitosamente.</p>
    <div style="background:#f0f4f8;padding:16px;border-radius:8px;margin:16px 0">
      <p style="margin:4px 0"><b>Curso:</b> {curso}</p>
      <p style="margin:4px 0"><b>Docente:</b> {docente}</p>
      <p style="margin:4px 0"><b>Fecha:</b> {fecha}</p>
      <p style="margin:4px 0"><b>Hora:</b> {hora}</p>
      <p style="margin:4px 0"><b>Confianza:</b> {int(confianza * 100)}%</p>
    </div>
    <p>Si no fuiste tú, contacta inmediatamente a tu docente.</p>
    """
    _send(email, f"Asistencia registrada - {curso} ✅", _base_template(content))