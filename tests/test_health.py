import unittest
from datetime import datetime
from app.main import app, health_check, read_root

class TestHealthEndpoint(unittest.TestCase):
    def test_read_root(self):
        result = read_root()
        self.assertEqual(result, {"message": "Welcome to FastAPI WebApp"})

    def test_health_check(self):
        result = health_check()
        self.assertEqual(result.status, "healthy")
        self.assertEqual(result.service, "fastapi-webapp")
        dt = datetime.fromisoformat(result.timestamp)
        self.assertIsNotNone(dt)

    def test_routes_registered(self):
        routes = [route.path for route in app.routes]
        self.assertIn("/", routes)
        self.assertIn("/health", routes)

if __name__ == "__main__":
    unittest.main()
