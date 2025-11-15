# 1. Python 이미지 기반
FROM python:3.11-slim

# 2. 환경 변수 설정
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3. 리눅스 패키지 업데이트 및 필수 의존성 설치 (psycopg2 등 쓰일 때 대비)
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 4. 작업 디렉토리
WORKDIR /app

# 5. requirements.txt 복사 및 설치
#    로컬: DJANGO/mysite/requirements.txt
COPY mysite/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# 6. Django 프로젝트 전체 복사
#    mysite 폴더 내용을 /app 으로 그대로 복사
COPY mysite/ /app/

# 7. static 파일 준비
RUN python manage.py collectstatic --noinput || true

# 8. 기본 환경변수 (DJANGO_SETTINGS_MODULE)
#    settings.py 위치: mysite/config/settings.py
ENV DJANGO_SETTINGS_MODULE=config.settings

# 9. 컨테이너 실행 명령: gunicorn
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]