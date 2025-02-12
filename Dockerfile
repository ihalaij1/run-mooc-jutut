FROM apluslms/service-base:django-1.13

# Set container related configuration via environment variables
ENV CONTAINER_TYPE="jutut" \
    JUTUT_LOCAL_SETTINGS="/srv/jutut-cont-settings.py" \
    JUTUT_SECRET_KEY_FILE="/local/jutut/secret_key.py"

COPY rootfs /

ARG BRANCH=master
RUN adduser --system --no-create-home --disabled-password --gecos "MOOC Jutut webapp server,,," --home /srv/jutut --ingroup nogroup jutut \
  && mkdir /srv/jutut && chown jutut.nogroup /srv/jutut && cd /srv/jutut \
\
  # 1) clone, prebuild .pyc files
  && git clone --quiet --single-branch --branch $BRANCH https://github.com/apluslms/mooc-jutut.git . \
  && (echo "On branch $(git rev-parse --abbrev-ref HEAD) | $(git describe)"; echo; git log -n5) > GIT \
  && rm -rf .git \
  && python3 -m compileall -q . \
\
  # 2) install requirements, remove the file, remove unrequired locales and tests
  && pip_install -r requirements.txt \
  && rm requirements.txt \
  && find /usr/local/lib/python* -type d -regex '.*/locale/[a-z_A-Z]+' -not -regex '.*/\(en\|fi\|sv\)' -print0 | xargs -0 rm -rf \
  && find /usr/local/lib/python* -type d -name 'tests' -print0 | xargs -0 rm -rf \
\
 # 3) preprocess
 && export \
    JUTUT_SECRET_KEY="-" \
    JUTUT_CACHES="{\"default\": {\"BACKEND\": \"django.core.cache.backends.dummy.DummyCache\"}}" \
 && python3 manage.py compilemessages 2>&1 \
 && create-db.sh jutut jutut django-migrate.sh \
 && :

EXPOSE 8082
WORKDIR /srv/jutut/
CMD [ "manage", "runserver", "0.0.0.0:8082" ]
