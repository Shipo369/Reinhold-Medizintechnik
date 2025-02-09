import React from 'react';
import { motion } from 'framer-motion';
import { BookOpen, Stethoscope, Monitor } from 'lucide-react';

interface CategoryCardProps {
  icon: React.ReactNode;
  title: string;
  description: string;
  image?: string;
}

function CategoryCard({ icon, title, description, image }: CategoryCardProps) {
  return (
    <motion.div
      whileHover={{ y: -5 }}
      className="relative bg-white/80 backdrop-blur-sm rounded-xl shadow-lg overflow-hidden group"
    >
      {image && (
        <div className="absolute inset-0 bg-cover bg-center z-0 opacity-10 group-hover:opacity-20 transition-opacity duration-300" style={{ backgroundImage: `url(${image})` }} />
      )}
      <div className="relative z-10 p-6 flex flex-col items-center text-center">
        <div className="bg-gradient-to-br from-blue-500 via-blue-600 to-blue-700 p-4 rounded-xl shadow-md text-white mb-4">
          {icon}
        </div>
        <h3 className="text-xl font-semibold text-gray-900 mb-2">{title}</h3>
        <p className="text-gray-600">{description}</p>
      </div>
    </motion.div>
  );
}

export function Hero() {
  return (
    <div className="relative pt-16 min-h-screen bg-gradient-to-br from-gray-50 via-blue-50 to-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center py-16 sm:py-20">
          <motion.h1 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-4xl sm:text-5xl md:text-6xl font-bold tracking-tight leading-tight"
          >
            <span className="block text-transparent bg-clip-text bg-gradient-to-r from-blue-600 via-blue-700 to-blue-800 leading-normal">
              Schulungsportal für
            </span>
            <span className="block text-gray-900 mt-2">
              Medizintechniker
            </span>
          </motion.h1>
          
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            className="mt-8 max-w-3xl mx-auto"
          >
            <p className="text-lg sm:text-xl text-gray-600 leading-relaxed">
              Professionelle Weiterbildung für Medizintechniker mit praxisnahen Schulungen und Zertifizierungen
            </p>
          </motion.div>

          <div className="mt-16 grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-6 max-w-5xl mx-auto">
            <CategoryCard
              icon={<BookOpen className="h-12 w-12" />}
              title="Geräteeinweisung"
              description="Zertifizierte Schulungen für medizinische Geräte"
            />
            <CategoryCard
              icon={<Stethoscope className="h-12 w-12" />}
              title="Wartung & Service"
              description="Wartung und Instandhaltung medizinischer Geräte"
              image="https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?auto=format&fit=crop&q=80"
            />
            <CategoryCard
              icon={<Monitor className="h-12 w-12" />}
              title="MTK & STK"
              description="Messtechnische und Sicherheitstechnische Kontrollen nach MPBetreibV"
            />
          </div>
        </div>
      </div>
    </div>
  );
}