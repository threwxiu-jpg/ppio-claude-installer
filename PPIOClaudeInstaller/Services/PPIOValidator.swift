import Foundation

enum PPIOValidator {
    static func validate(apiKey: String, modelID: String) async -> (success: Bool, error: String?) {
        let url = URL(string: "https://api.ppio.com/anthropic/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "model": modelID,
            "max_tokens": 5,
            "messages": [
                ["role": "user", "content": "hi"]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return (false, "Failed to build request: \(error.localizedDescription)")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Invalid response")
            }

            switch httpResponse.statusCode {
            case 200:
                return (true, nil)
            case 401:
                return (false, "API Key invalid or expired (401)")
            case 403:
                return (false, "Access denied (403). Check your API key permissions.")
            case 404:
                return (false, "Model not found (404). Check the model ID: \(modelID)")
            case 429:
                return (false, "Rate limited (429). Please try again later.")
            default:
                return (false, "Server returned status \(httpResponse.statusCode)")
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }
}
