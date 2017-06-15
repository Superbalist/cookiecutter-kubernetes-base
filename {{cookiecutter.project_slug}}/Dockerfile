FROM {{ cookiecutter.base_image }}

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="{{ cookiecutter.project_name }}" \
      org.label-schema.description="{{ cookiecutter.project_short_description }}" \
      org.label-schema.url="e.g. https://github.com/superbalist/cookiecutter-kubernetes-base" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="e.g. https://github.com/superbalist/cookiecutter-kubernetes-base" \
{%- if cookiecutter.vendor %}
      org.label-schema.vendor="{{ cookiecutter.vendor }}" \
{%- endif %}
      org.label-schema.schema-version="1.0"

CMD ["tail", "-f", ".dockerenv"]
