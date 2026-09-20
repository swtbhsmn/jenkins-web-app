import unittest
from datetime import datetime
from app.main import app, health_check, read_root

class TestHealthEndpoint(unittest.TestCase):
    def test_read_root_direct(self):
        result = read_root()
        self.assertEqual(result, {"message": "Welcome to FastAPI WebApp"})

    def test_health_check_direct(self):
        result = health_check()
        self.assertEqual(result.status, "healthy")
        self.assertEqual(result.service, "fastapi-webapp")
        # Validate timestamp format
        dt = datetime.fromisoformat(result.timestamp)
        self.assertIsNotNone(dt)

    def test_endpoint_registered(self):
        routes = [route.path for route in app.routes]
        self.assertIn("/", routes)
        self.assertIn("/health", routes)

    def test_via_testclient_if_available(self):
        try:
            from fastapi.testclient import TestClient
            client = TestClient(app)
            response = client.get("/health")
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data["status"], "healthy")
            self.assertEqual(data["service"], "fastapi-webapp")
        except RuntimeError:
            # httpx not installed in offline sandbox environment
            pass

if __name__ == "__main__":
    unittest.main()
