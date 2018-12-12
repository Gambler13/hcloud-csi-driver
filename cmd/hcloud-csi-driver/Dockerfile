# Copyright 2018 DigitalOcean
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#github.com/apricote/hcloud-csi-driver/cmd/hcloud-csi-driver
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG GO_VERSION=1.9.2
FROM golang:${GO_VERSION}-alpine AS build-stage
#PUR ALL ARGS AFTER "FROM" INSTRUCTION
MAINTAINER christian.schlatter@ionesoft.ch

WORKDIR /go/src/

COPY ./ github.com/apricote/hcloud-csi-driver

RUN CGO_ENABLED=1 GOOS=`go env GOHOSTOS` GOARCH=`go env GOHOSTARCH` go build -o /hcloud-csi-driver github.com/apricote/hcloud-csi-driver/cmd/hcloud-csi-driver/

FROM alpine:3.7

RUN apk add --no-cache ca-certificates e2fsprogs findmnt

COPY --from=build-stage /hcloud-csi-driver /bin/

ENTRYPOINT ["/bin/hcloud-csi-driver"]

