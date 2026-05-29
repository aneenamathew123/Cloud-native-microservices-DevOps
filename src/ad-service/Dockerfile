##generate the ad service 
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /usr/src/app

COPY gradlew* ./

COPY build.gradle settings.gradle* ./

COPY ./gradle ./gradle

RUN chmod +x gradlew

RUN ./gradlew downloadRepos

COPY . .

RUN ./gradlew installDist -PprotoSourceDir=/usr/src/app/pb

########################################################

FROM gcr.io/distroless/java21-debian12 AS release

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app ./

ENV AD_PORT=8080

ENV FEATURE_FLAG_GRPC_SERVICE_ADDR=featureflagservice:50053

ENTRYPOINT ["./build/install/opentelemetry-demo-ad/bin/Ad"]