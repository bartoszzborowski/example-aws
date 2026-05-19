#!/bin/sh
set -e

# config:cache runs at container start so runtime env vars are visible to Laravel.
# route:cache and view:cache are done at build time (no env var dependency).
php artisan config:cache
php artisan migrate --force

exec "$@"
