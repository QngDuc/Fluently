import { Controller, Get, Module } from "@nestjs/common";

@Controller()
class HealthController {
  @Get("health")
  health() {
    return { status: "ok" };
  }
}

@Module({
  imports: [],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
