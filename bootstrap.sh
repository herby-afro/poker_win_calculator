#!/bin/bash

# bootstrap.sh - Script universal para ejecutar apps Python sin complicaciones
# Uso: bash bootstrap.sh poker_win_calculator_web.py

set -e  # Detener en errores

SCRIPT_NAME="$1"
REQUIREMENTS="requirements.txt"
ENV_DIR="poker_venv9"

if [ -z "$SCRIPT_NAME" ]; then
  echo "❗ Debes proporcionar el archivo Python a ejecutar: bash bootstrap.sh <script.py>"
  exit 1
fi

# Verifica que Python 3 esté instalado
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3 no está instalado."
  exit 1
fi

# Instala whiptail o dialog si no está presente
if ! command -v whiptail &> /dev/null && ! command -v dialog &> /dev/null; then
  echo "📦 Instalando herramienta de diálogo (requiere sudo)..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &> /dev/null; then
      sudo apt update && sudo apt install -y whiptail
    elif command -v dnf &> /dev/null; then
      sudo dnf install -y newt
    elif command -v pacman &> /dev/null; then
      sudo pacman -Sy --noconfirm newt
    fi
  fi
fi

# Crea entorno virtual si no existe
if [ ! -d "$ENV_DIR" ]; then
 echo "📦 Creando entorno virtual..."
 python3 -m venv "$ENV_DIR"
fi

# Activar entorno virtual
source "$ENV_DIR/bin/activate"

# Instalar dependencias del sistema

echo "Instalando dependencias del sistema..."
sudo apt update && sudo apt install -y \
  make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
  libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev \
  libdb-dev libgmp-dev


# Detectar dependencias si requirements.txt no existe
if [ ! -f "$REQUIREMENTS" ]; then
  echo "🔍 Analizando dependencias del script..."
  grep -Po '^\s*(import|from)\s+\K\w+' "$SCRIPT_NAME" | sort -u > .tmp_imports.txt

  echo "# Requisitos generados automáticamente" > "$REQUIREMENTS"
  while read -r mod; do
    case $mod in
      streamlit|cython|eval7)
        echo "$mod" >> "$REQUIREMENTS"
        ;;
      *) ;;
    esac
  done < .tmp_imports.txt
  rm .tmp_imports.txt
fi

# Crear requirements.txt básico si sigue sin existir
if [ ! -f "$REQUIREMENTS" ]; then
  echo "📄 Generando '$REQUIREMENTS' con dependencias comunes..."
  echo -e "streamlit\ncython\neval7" > "$REQUIREMENTS"
fi

# Instalar dependencias
echo "📥 Instalando dependencias..."
pip install --upgrade pip

pip install -r "$REQUIREMENTS"

# Ejecutar script según corresponda
if grep -q "streamlit" "$SCRIPT_NAME"; then
  echo "🚀 Ejecutando Streamlit App: $SCRIPT_NAME..."
  streamlit run "$SCRIPT_NAME"
else
  echo "🚀 Ejecutando script Python: $SCRIPT_NAME..."
  if ! python3 "$SCRIPT_NAME"; then
    echo "⚠️ Fallo en la ejecución. ¿Faltan dependencias?"

    if command -v whiptail &> /dev/null; then
      whiptail --title "Error" --msgbox "La ejecución falló. Revisa el script o los módulos." 10 60
    elif command -v dialog &> /dev/null; then
      dialog --msgbox "La ejecución falló. Revisa el script o los módulos." 10 60
    else
      echo "⚠️ No se pudo mostrar diálogo gráfico (instala 'whiptail' o 'dialog')."
    fi

    exit 1
  fi
fi
