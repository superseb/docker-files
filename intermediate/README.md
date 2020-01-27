# intermediate

```
docker run --rm -v $PWD/testcerts:/tmp/certs/files -e TF_VAR_ip_addresses='["127.0.0.1"]' -e TF_VAR_dns_names='["yolo.seb.local"]' superseb/intermediate
```
