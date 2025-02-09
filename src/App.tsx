import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Header } from './components/Header';
import { Hero } from './components/Hero';
import { Footer } from './components/Footer';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { TrainingArea } from './pages/TrainingArea';
import { DeviceManagement } from './pages/DeviceManagement';
import { EventManagement } from './pages/EventManagement';
import { CertificatesPage } from './pages/CertificatesPage';
import { CertificateManagement } from './pages/CertificateManagement';
import { UserManagement } from './pages/UserManagement';
import { ExamBoard } from './pages/ExamBoard';
import { ExamAttemptsDashboard } from './pages/ExamAttemptsDashboard';
import { Impressum } from './pages/Impressum';
import { Privacy } from './pages/Privacy';
import { Terms } from './pages/Terms';
import { PresentationPage } from './pages/PresentationPage';
import { DocumentsPage } from './pages/DocumentsPage';
import { AccessManagement } from './pages/AccessManagement';

export default function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-50 flex flex-col">
        <Routes>
          <Route
            path="/"
            element={
              <>
                <Header />
                <Hero />
                <Footer />
              </>
            }
          />
          <Route path="/login" element={<Login />} />
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/schulungen" element={<TrainingArea />} />
          <Route path="/geraete" element={<DeviceManagement />} />
          <Route path="/events" element={<EventManagement />} />
          <Route path="/zertifikate" element={<CertificatesPage />} />
          <Route path="/zertifikate/verwaltung" element={<CertificateManagement />} />
          <Route path="/users" element={<UserManagement />} />
          <Route path="/pruefungen" element={<ExamBoard />} />
          <Route path="/pruefungen/teilnahmen" element={<ExamAttemptsDashboard />} />
          <Route path="/praesentation" element={<PresentationPage />} />
          <Route path="/dokumente" element={<DocumentsPage />} />
          <Route path="/access" element={<AccessManagement />} />
          <Route path="/impressum" element={<Impressum />} />
          <Route path="/datenschutz" element={<Privacy />} />
          <Route path="/agb" element={<Terms />} />
        </Routes>
      </div>
    </Router>
  );
}