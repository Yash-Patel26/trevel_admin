import request from "supertest";
import { app } from "../src/server";

describe("auth endpoints", () => {
  it("fails when missing email/password", async () => {
    const res = await request(app).post("/auth/login").send({});
    expect(res.status).toBe(400);
    expect(res.body.message).toBe("Validation error");
  });

  it("fails with invalid credentials", async () => {
    const res = await request(app)
      .post("/auth/login")
      .send({ email: "invalid@example.com", password: "wrong" });
    expect(res.status).toBe(401);
  });

  it("successfully logs in with valid credentials", async () => {
    const res = await request(app)
      .post("/auth/login")
      .send({ email: "admin@example.com", password: "admin123" });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user).toBeDefined();
  });

  it("refreshes access token with valid refresh token", async () => {
    const loginRes = await request(app)
      .post("/auth/login")
      .send({ email: "admin@example.com", password: "admin123" });
    const refreshToken = loginRes.body.refreshToken;

    const res = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeDefined();
  });

  it("fails to refresh with invalid token", async () => {
    const res = await request(app)
      .post("/auth/refresh")
      .send({ refreshToken: "invalid-token" });
    expect(res.status).toBe(401);
  });

  it("gets current user with valid token", async () => {
    const loginRes = await request(app)
      .post("/auth/login")
      .send({ email: "admin@example.com", password: "admin123" });
    const token = loginRes.body.accessToken;

    const res = await request(app)
      .get("/auth/me")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.user).toBeDefined();
  });

  it("fails to get current user without token", async () => {
    const res = await request(app).get("/auth/me");
    expect(res.status).toBe(401);
  });
});
