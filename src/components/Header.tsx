import React from 'react';
import { Link } from 'react-router-dom';

export function Header() {
  return (
    <header className="fixed w-full bg-white/90 backdrop-blur-sm shadow-sm z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-24">
          <Link to="/" className="flex items-center">
            <img 
              src="https://www.reinhold-medizintechnik.de/files/default/images/corporate/logo.png" 
              alt="Reinhold Medizintechnik Logo" 
              className="h-16 w-auto"
            />
          </Link>

          <Link
            to="/login"
            className="inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-xl text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:from-blue-600 hover:via-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 shadow-md hover:shadow-lg"
          >
            <span className="mr-2">Anmelden</span>
          </Link>
        </div>
      </div>
    </header>
  );
}