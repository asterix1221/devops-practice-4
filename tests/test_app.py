"""Unit tests for the Flask routes."""

import unittest

from app import app


class FlaskAppTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_index_returns_running_status(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["status"], "running")
        self.assertIn("DevOps Practice 4", response.get_json()["message"])

    def test_health_returns_ok(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "ok"})


if __name__ == "__main__":
    unittest.main(verbosity=2)
