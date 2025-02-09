import React from 'react';
import { Link } from 'react-router-dom';
import { Mail, Phone, Printer } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-white border-t">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Reinhold Medizintechnik GmbH</h3>
            <p className="text-sm text-gray-600">
              Möhnestraße 55<br />
              59755 Arnsberg<br />
              Kaiserhaus
            </p>
          </div>
          
          <div>
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Kontakt</h3>
            <div className="space-y-2">
              <div className="flex items-center text-sm text-gray-600">
                <Phone className="h-4 w-4 mr-2" />
                <span>Telefon: 02932 429 20 30</span>
              </div>
              <div className="flex items-center text-sm text-gray-600">
                <Printer className="h-4 w-4 mr-2" />
                <span>Telefax: 02932 429 20 32</span>
              </div>
              <div className="flex items-center text-sm text-gray-600">
                <Mail className="h-4 w-4 mr-2" />
                <a 
                  href="mailto:info@reinhold-medizintechnik.de"
                  className="hover:text-blue-600 transition-colors"
                >
                  info@reinhold-medizintechnik.de
                </a>
              </div>
            </div>
          </div>

          <div className="text-right">
            <div className="flex flex-col items-end space-y-2">
              <Link
                to="/impressum"
                className="text-sm text-gray-600 hover:text-blue-600 transition-colors"
              >
                Impressum
              </Link>
              <Link
                to="/datenschutz"
                className="text-sm text-gray-600 hover:text-blue-600 transition-colors"
              >
                Datenschutz
              </Link>
              <Link
                to="/agb"
                className="text-sm text-gray-600 hover:text-blue-600 transition-colors"
              >
                AGB
              </Link>
              <div className="text-sm text-gray-500 mt-2">
                <span>© 2025 Reinhold Medizintechnik GmbH</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}