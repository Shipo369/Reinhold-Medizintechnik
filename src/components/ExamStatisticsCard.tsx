import React from 'react';

interface ExamStatisticsCardProps {
  title: string;
  passRate: number;
  averageScore: number;
  passingScore: number;
  totalAttempts: number;
  passedAttempts: number;
}

export function ExamStatisticsCard({
  title,
  passRate,
  averageScore,
  passingScore,
  totalAttempts,
  passedAttempts
}: ExamStatisticsCardProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">{title}</h3>
      <div className="space-y-3">
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Bestehensquote:</span>
          <span className="font-medium">{passRate.toFixed(1)}%</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Durchschnitt:</span>
          <span className="font-medium">{averageScore.toFixed(1)}%</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Bestehensgrenze:</span>
          <span className="font-medium">{passingScore}%</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Teilnahmen:</span>
          <span className="font-medium">{totalAttempts}</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="text-gray-600">Bestanden:</span>
          <span className="font-medium">{passedAttempts}</span>
        </div>
      </div>
    </div>
  );
}