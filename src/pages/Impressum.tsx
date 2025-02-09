import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';

export function Impressum() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gray-50 pt-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate(-1)}
                className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                title="Zurück"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              <h1 className="text-2xl font-bold text-gray-900">Impressum</h1>
            </div>
          </div>

          <div className="p-6 space-y-6">
            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Angaben gemäß § 5 TMG</h2>
              <p className="text-gray-700">
                Reinhold Medizintechnik GmbH<br />
                Möhnestraße 55<br />
                59755 Arnsberg<br />
                Deutschland
              </p>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Kontakt</h2>
              <p className="text-gray-700">
                Fon: +49 (0) 2932-4292030<br />
                Fax: +49 (0) 2932-4292032<br />
                E-Mail: <a href="mailto:info@reinhold-medizintechnik.de" className="text-blue-600 hover:text-blue-800">info@reinhold-medizintechnik.de</a>
              </p>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Vertretung</h2>
              <p className="text-gray-700">
                Vertretungsberechtigter Geschäftsführer: Markus Reinhold
              </p>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Verantwortlich für journalistisch-redaktionelle Inhalte</h2>
              <p className="text-gray-700">
                Markus Reinhold<br />
                Möhnestraße 55<br />
                59755 Arnsberg
              </p>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Registereintrag</h2>
              <p className="text-gray-700">
                Handelsregister-Nummer: HRB 14042<br />
                Registergericht: Amtsgericht Arnsberg<br />
                Sitz der Gesellschaft: Arnsberg
              </p>
            </div>

            <div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">Umsatzsteuer-ID</h2>
              <p className="text-gray-700">
                Umsatzsteuer-Identifikationsnummer gemäß § 27a Umsatzsteuergesetz:<br />
                DE 346984190
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}