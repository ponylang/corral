FROM ponylang/ponyc:release-alpine AS build

COPY Makefile LICENSE VERSION /src/corral/
COPY appdirs /src/corral/appdirs/
COPY pony-semver /src/corral/pony-semver/
COPY corral /src/corral/corral/

WORKDIR /src/corral

RUN make arch=x86-64 static=true linker=bfd \
 && make install

FROM alpine:3.10

COPY --from=build /usr/local/bin/corral /usr/local/bin/corral

CMD corral
