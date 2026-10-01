docker pull noahclanman/gcp:latest
docker rm -f umbra 2>/dev/null || true

docker run -d \
  --name umbra \
  --restart unless-stopped \
  -p 8080:8080 \
  noahclanman/gcp:latest
