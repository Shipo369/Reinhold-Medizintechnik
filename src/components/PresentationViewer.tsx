import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { X, ChevronLeft, ChevronRight } from 'lucide-react';

interface PresentationViewerProps {
  presentation: {
    id: string;
    content: string;
    title: string;
  };
  onClose: () => void;
}

export function PresentationViewer({ presentation, onClose }: PresentationViewerProps) {
  const [currentSlide, setCurrentSlide] = useState(0);
  const [slides, setSlides] = useState<string[]>([]);

  useEffect(() => {
    // Parse HTML content into slides
    const parser = new DOMParser();
    const doc = parser.parseFromString(presentation.content, 'text/html');
    const slideElements = doc.querySelectorAll('.slide');
    setSlides(Array.from(slideElements).map(el => el.outerHTML));
  }, [presentation]);

  // Handle keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === 'Space') {
        setCurrentSlide(prev => Math.min(slides.length - 1, prev + 1));
      } else if (e.key === 'ArrowLeft') {
        setCurrentSlide(prev => Math.max(0, prev - 1));
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [slides.length]);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full h-full bg-white flex flex-col"
      >
        <div className="flex justify-between items-center px-6 py-4 border-b bg-white/90 backdrop-blur-sm">
          <h3 className="text-lg font-medium text-gray-900">
            {presentation.title}
          </h3>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-500 rounded-lg transition-colors"
            title="Schließen"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-hidden relative bg-gray-100">
          <div className="relative h-full flex flex-col">
            {/* Slide Content */}
            <div className="flex-1 overflow-auto">
              <div 
                className="h-full flex items-center justify-center p-8"
                dangerouslySetInnerHTML={{ __html: slides[currentSlide] || '' }}
              />
            </div>

            {/* Navigation Controls */}
            <div className="sticky bottom-0 left-0 right-0 flex justify-center items-center space-x-4 bg-white/90 backdrop-blur-sm py-3 px-4 border-t border-gray-200">
              <button
                onClick={() => setCurrentSlide(prev => Math.max(0, prev - 1))}
                disabled={currentSlide === 0}
                className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors disabled:opacity-50"
              >
                <ChevronLeft className="h-6 w-6" />
              </button>
              <span className="text-sm font-medium text-gray-700 bg-gray-100 px-4 py-2 rounded-lg min-w-[100px] text-center">
                {currentSlide + 1} / {slides.length}
              </span>
              <button
                onClick={() => setCurrentSlide(prev => Math.min(slides.length - 1, prev + 1))}
                disabled={currentSlide === slides.length - 1}
                className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors disabled:opacity-50"
              >
                <ChevronRight className="h-6 w-6" />
              </button>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}