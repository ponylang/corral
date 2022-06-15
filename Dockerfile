FROM ponylang/ponyc:release-alpine AS build

WORKDIR /src/corral

COPY Makefile LICENSE VERSION /src/corral/

WORKDIR /src/corral/corral

COPY corral /src/corral/corral/

WORKDIR /src/corral

RUN make arch=x86-64 static=true linker=bfd \
 && make install

FROM alpine:3.16

COPY --from=build /usr/local/bin/corral /usr/local/bin/corral

CMD corral
