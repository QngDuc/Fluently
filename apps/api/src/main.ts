import { existsSync, readFileSync } from "fs";
import { resolve } from "path";
import { NestFactory } from "@nestjs/core";
import { SwaggerModule, DocumentBuilder } from "@nestjs/swagger";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();

  const config = new DocumentBuilder()
    .setTitle("Fluently API")
    .setDescription("Fluently API documentation")
    .setVersion("1.0")
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup("docs", app, document);

  const specPathCandidates = [
    resolve(process.cwd(), "src/openapi/fluently-openapi.yaml"),
    resolve(__dirname, "..", "src", "openapi", "fluently-openapi.yaml"),
    resolve(__dirname, "openapi", "fluently-openapi.yaml"),
  ];

  const specPath = specPathCandidates.find((candidate) =>
    existsSync(candidate),
  );

  if (specPath) {
    const specContent = readFileSync(specPath, "utf8");
    app.getHttpAdapter().get("/docs/openapi.yaml", (_req, res) => {
      res.type("application/x-yaml").send(specContent);
    });
  }

  await app.listen(process.env.API_PORT || 4000);
}

bootstrap();
