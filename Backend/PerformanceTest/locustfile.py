from locust import HttpUser, task, between

class TAssistUser(HttpUser):

    wait_time = between(1, 3)

    @task
    def login(self):

        self.client.post(
            "/api/v1/login",
            json={
                "email":"mhs.testing@example.com",
                "password":"password123"
            }
        )