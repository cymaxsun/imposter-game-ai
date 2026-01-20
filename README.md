# 🎭 Imposter Finder

An AI-powered party game where players try to find the **Odd One Out**! Feature a premium "Stitch"-inspired UI, secure word generation, and seamless cross-platform play.

**Built with Flutter & AWS Serverless.**

---

## ✨ Features

- **📱 Beautiful Flutter UI**: A polished, "Stitch"-themed interface with smooth animations and haptic feedback.
- **🔒 Secure Generation**: Uses **Apple App Attest** and **JWT Session Binding** to prevent API abuse.
- **🤖 AI-Powered**: Uses **Google Gemini** to generate infinite, contextual word lists.
- **🔄 Intelligent Caching**: Optimizes API costs with smart caching and auto-renewing sessions.
- **⚡ Serverless Backend**: Powered by **AWS Lambda** and **API Gateway** for zero-maintenance scaling.

## 📂 Project Structure

- **`imposter_finder/`**: The Flutter mobile application (iOS/Android).
- **`api/`**: The AWS SAM (Serverless Application Model) backend.

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.x+)
- **AWS SAM CLI**
- **Node.js 18+** (for backend)
- **Gemini API Key**

### 1. Mobile App (Flutter)

```bash
cd imposter_finder
flutter pub get
flutter run
```

### 2. Backend (AWS SAM)

1.  Navigate to the API folder:
    ```bash
    cd api
    ```
2.  Create a `.env` file with your Gemini API key:
    ```bash
    echo "GEMINI_API_KEY=your_key_here" > .env
    ```
3.  Build and Deploy:
    ```bash
    sam build
    sam deploy --guided
    ```

## 🛠️ Tech Stack

### Mobile (Client)
- **Framework**: Flutter (Dart)
- **State Management**: standard `setState` + `Services` pattern
- **Security**: `app_device_integrity` (Attestation), `flutter_secure_storage`

### Backend (Server)
- **Runtime**: Node.js 20.x
- **Infrastructure**: AWS Lambda, API Gateway
- **AI**: `@google/genai` SDK
- **Security**: Apple App Attest verification, JWT (JsonWebToken)

## 🔐 Security Architecture

This app implements a high-security "Handshake" protocol:
1.  **Challenge**: App requests a cryptographic nonce from the server.
2.  **Attestation**: App signs the nonce using the device's Secure Enclave (Apple App Attest).
3.  **Verification**: Server validates the signature with Apple.
4.  **Session**: If valid, server issues a short-lived **Session JWT**.
5.  **Access**: App uses the JWT for subsequent API calls (Word Generation).

## 📄 License

MIT
