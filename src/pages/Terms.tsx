import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';

export function Terms() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gray-50 pt-20">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
              <h1 className="text-2xl font-bold text-gray-900">Allgemeine Geschäfts- und Lieferbedingungen</h1>
            </div>
          </div>

          <div className="p-6">
            <div className="prose max-w-none text-gray-700 whitespace-pre-wrap">
              {`Allgemeine Geschäfts- und Lieferbedingungen

§ 1 Geltungsbereich
(1) Diese Allgemeine Geschäftsbedingungen (im Folgenden „AGB") finden Anwendung auf alle Lieferungen und Leistungen, die

Reinhold Medizintechnik GmbH
Inhaber: Markus Reinhold
Möhnestraße 55
59755 Arnsberg
Fon: +49 (0) 2932-4292030
Fax: + 49 (0) 2932-4292032
E-Mail-Adresse: info@reinhold-medizintechnik.de
UStID-Nr.: DE346984190

(im Folgenden „uns") an Ihnen als unseren Kunden erbringt. Die AGB gelten unabhängig davon, ob Sie Verbraucher, Unternehmer oder Kaufmann sind.

(2) Alle zwischen Ihnen und uns im Zusammenhang mit der Lieferung und Leistungen getroffenen Vereinbarungen ergeben sich insbesondere aus diesen AGB, unseren schriftlichen Auftragsbestätigungen und unseren Annahmeerklärungen.

(3) Maßgebend ist die jeweils bei Abschluss des Vertrages gültige Fassung der AGB.

(4) Abweichende Bedingungen des Kunden akzeptieren wir nicht. Dies gilt auch, wenn wir der Einbeziehung nicht ausdrücklich widersprechen.

§ 2 Vertragsschluss
(1) Die Präsentation der Waren und Leistungen insbesondere im Internet stellen kein bindendes Angebot zum Abschluss eines Vertrages zur Lieferung und Leistung dar, sondern eine Einladung an Sie, die präsentierten Waren und Leistungen zu bestellen.

(2) Mit dem Absenden einer Bestellung per Fax oder per Telefon oder per E-Mail geben Sie eine rechtsverbindliche Bestellung ab. Sie sind an die Bestellung für die Dauer von zwei Wochen nach Abgabe der Bestellung, maßgebend ist das Datum des Faxeingangs bzw. E-Mail-Eingangs bei uns oder der Zeitpunkt der telefonischen Bestellannahme durch uns, gebunden. Ihr gegebenenfalls nach § 3 bestehendes Recht, Ihre Bestellung zu widerrufen, bleibt hiervon unberührt.

(3) Wir werden den Zugang Ihrer per Fax, E-Mail oder telefonisch abgegebenen Bestellung unverzüglich schriftlich, in Textform, bestätigen. In einer solchen Bestätigung liegt noch keine verbindliche Annahme der Bestellung, es sei denn, darin wird neben der Bestätigung des Zugangs zugleich die Annahme erklärt.

(4) Ein Vertrag kommt erst zustande, wenn wir Ihre Bestellung durch eine Annahmeerklärung oder durch Lieferung der bestellten Artikel annehmen.

(5) Wir nehmen Bestellungen aus dem Ausland nur schriftlich entgegen (per Fax, per Post, per E-Mail).

(6) Sollte die Lieferung der von Ihnen bestellten Ware oder Leistungen nicht möglich sein, etwa weil die entsprechende Ware nicht auf Lager ist, oder die Leistung nicht angeboten werden kann, sehen wir von einer Annahmeerklärung ab. In diesem Fall kommt ein Vertrag nicht zustande. Wir werden Sie darüber unverzüglich informieren und bereits erhaltene Gegenleistungen unverzüglich zurückerstatten.

§ 3 Widerrufsrecht
(1) Wenn Sie Verbraucher sind (also eine natürliche Person, die die Bestellung zu einem Zweck abgibt, der weder Ihrer gewerblichen oder selbständigen beruflichen Tätigkeit zugerechnet werden kann), steht Ihnen nach Maßgabe der gesetzlichen Bestimmungen ein Widerrufsrecht zu.

(2) Machen Sie als Verbraucher von Ihrem Widerrufsrecht nach Ziffer 1 Gebrauch, so haben Sie die regelmäßigen Kosten der Rücksendung zu tragen.

(3) Im Übrigen gelten für das Widerrufsrecht die Regelungen, die im Einzelnen in der folgenden Widerrufsbelehrung wiedergegeben sind:

Widerrufsbelehrung

Sie haben das Recht, binnen vierzehn Tagen ohne Angabe von Gründen diesen Vertrag zu widerrufen.

Die Widerrufsfrist beträgt vierzehn Tage ab dem Tag an dem Sie oder ein von Ihnen benannter Dritter, der nicht Beförderer ist, die Waren in Besitz genommen haben bzw. hat.

Um Ihr Widerrufsrecht auszuüben, müssen Sie uns

Reinhold Medizintechnik GmbH
Möhnestraße 55
59755 Arnsberg
Fon: +49 (0) 2932-4292030
Fax: + 49 (0) 2932-4292032
E-Mail-Adresse: info@reinhold-medizintechnik.de

mittels einer eindeutigen Erklärung (z.B. ein mit der Post versandter Brief, Telefax oder E-Mail) über Ihren Entschluss, diesen Vertrag zu widerrufen, informieren. Sie können dafür das beigefügte Muster-Widerrufsformular verwenden, das jedoch nicht vorgeschrieben ist. Sie können das Muster-Widerrufsformular oder eine andere eindeutige Erklärung auch auf unserer Webseite https://www.reinhold-medizintechnik.de/downloads.html elektronisch ausfüllen und übermitteln. Machen Sie von dieser Möglichkeit Gebrauch, so werden wir Ihnen unverzüglich (z.B. per E-Mail) eine Bestätigung über den Eingang eines solchen Widerrufs übermitteln.

Zur Wahrung der Widerrufsfrist reicht es aus, dass Sie die Mitteilung über die Ausübung des Widerrufsrechts vor Ablauf der Widerrufsfrist absenden.

Folgen des Widerrufs

Wenn Sie diesen Vertrag widerrufen, haben wir Ihnen alle Zahlungen, die wir von Ihnen erhalten haben, einschließlich der Lieferkosten (mit Ausnahme der zusätzlichen Kosten, die sich daraus ergeben, dass Sie eine andere Art der Lieferung als die von uns angebotene, günstige Standardlieferung gewählt haben), unverzüglich und spätestens binnen vierzehn Tage ab dem Tag zurückzuzahlen, an dem die Mitteilung über Ihren Widerruf dieses Vertrags bei uns eingegangen ist. Für diese Rückzahlung verwenden wir dasselbe Zahlungsmittel, das Sie bei der ursprünglichen Transaktion eingesetzt haben, es sei denn, mit Ihnen wurde ausdrücklich etwas anderes vereinbart; in keinem Fall werden Ihnen wegen dieser Rückzahlung Entgelte berechnet. Wir können die Rückzahlung verweigern, bis wir die Ware wieder zurückerhalten haben oder bis Sie den Nachweis erbracht haben, dass Sie die Waren zurückgesandt haben, je nachdem welches der frühere Zeitpunkt ist.

Sie haben die Waren unverzüglich und in jedem Fall spätestens binnen vierzehn Tagen ab dem Tag, an dem Sie uns über den Widerruf dieses Vertrages unterrichten, an uns

Reinhold Medizintechnik GmbH
Möhnestraße 55
59755 Arnsberg

zurückzusenden oder zu übergeben. Die Frist ist gewahrt, wenn Sie die Waren vor Ablauf der Frist von vierzehn Tagen absenden.

Sie tragen die unmittelbaren Kosten der Rücksendung der Waren.

Sie müssen für einen etwaigen Wertverlust der Waren nur aufkommen, wenn dieser Wertverlust auf einen zur Prüfung der Beschaffenheit, Eigenschaften und Funktionsweise der Ware nicht notwendigen Umgang mit Ihnen zurückzuführen ist.

- Ende der Widerrufsbelehrung -

(4) Das Widerrufsrecht besteht nicht bei Fernabsatzverträgen

(a) Zur Lieferung von Waren, die nach Kundenspezifikation angefertigt wurden oder die eindeutig auf die persönlichen Bedürfnisse zugeschnitten sind oder die aufgrund ihrer Beschaffenheit nicht für eine Rücksendung geeignet sind oder schnell verderben können oder deren Verfallsdatum überschritten wurde,

(b) Zur Lieferung von Audio- oder Videoaufzeichnungen oder von Software, sofern Sie die gelieferten Datenträger entsiegelt haben.

(c) Verträge, bei denen der Verbraucher den Unternehmer ausdrücklich aufgefordert hat, ihn aufzusuchen, um dringende Reparatur- oder Instandhaltungsarbeiten vorzunehmen; dies gilt nicht hinsichtlich weiterer bei dem Besuch erbrachter Dienstleistungen, die der Verbraucher nicht ausdrücklich verlangt hat, oder hinsichtlich solcher bei dem Besuch gelieferter Waren, die bei der Instandhaltung oder Reparatur nicht unbedingt als Ersatzteile benötigt werden.

§ 4 Lieferbedingungen und Vorbehalt der Vorkasse
(1) Wir sind zu Teillieferungen berechtigt, soweit dies für Sie zumutbar ist.

(2) Die Lieferfrist beträgt circa zehn Werktage, soweit nichts anderes vereinbart wurde. Sie beginnt vorbehaltlich der Regelung in Absatz 3 – mit Vertragsschluss.

(3) Bei Bestellungen von Kunden mit Wohn- oder Geschäftssitz im Ausland oder bei begründeten Anhaltspunkten für ein Zahlungsausfallrisiko behalten wir uns vor, erst nach Erhalt des Kaufpreises nebst Versandkosten zu liefern (Vorbehalt der Vorkasse). Falls wir von dem Vorbehalt der Vorkasse Gebrauch machen, werden wir Sie unverzüglich unterrichten. In diesem Fall beginnt die Lieferfrist mit Bezahlung des Kaufpreises und der Versandkosten.

§ 5 Preise und Versandkosten
(1) Sämtliche Preisangaben in unserem Produktportfolio sind Bruttopreise inklusive der gesetzlichen Umsatzsteuer und verstehen sich zuzüglich anfallender Versandkosten. Die Versandkosten werden Ihnen mit der Angebotserstellung übersendet.

(2) Die im Produktportfolio genannten Preise sind gültig bis zum 31.12.2019. Für Druck- oder Übertragungsfehler bei der Preisbezeichnung übernehmen wir keine Haftung.

(3) Die Versandkostenpauschale pro Bestellung bis 10 kg beträgt 8,99 EUR, bis 30 kg beträgt die Versandkostenpauschale 14,99 EUR. Darüber hinaus ist eine individuelle Vereinbarung über die Versandkostenpauschale zu vereinbaren. Wünschen Sie eine Expresslieferung oder eine Zustellung auf deutschen Inseln, so ist diese individuell zu vereinbaren.

(4) Die Versandkosten für Lieferungen ins Ausland sind abweichend. Diese erfragen Sie bitte bei unserem Bestellservice-Team schriftlich unter nachfolgender Faxnummer +49 (0) 2932-4292032 oder per mail unter bestellung@reinhold-medizintechnik.de.

(5) Wenn wir Ihre Bestellung gemäß § 4 Abs.1 durch Teillieferung erfüllen, entstehen Ihnen nur bei der ersten Teillieferung Versandkosten. Erfolgen die Teillieferungen auf Ihren Wunsch, berechnen wir für jede Teillieferung Versandkosten.

(6) Wenn Sie Ihre Vertragserklärung wirksam gemäß § 3 widerrufen, können Sie unter den gesetzlichen Voraussetzungen die Erstattung bereits bezahlter Kosten für den Versand zu Ihnen (Kosten der Hin-Sendung) verlangen (vgl. zu sonstigen Widerrufsfolgen § 3 Abs.3).

§ 6 Zahlungsbedingungen und Aufrechnung
(1) Der Kaufpreis und die Versandkosten bzw. die Vergütung für die Dienstleistung sind spätestens 14 Tage nach Rechnungsdatum ohne Abzug, unter Angabe der Rechnungsnummer zu zahlen.

(2) Der Kaufpreis und die Versandkosten bzw. die Vergütung für die Dienstleistung sind auf das in der Rechnung angegebene Konto zu überweisen. Wir behalten uns vor, bestimmte Zahlungsarten von einer Bonitätsprüfung oder einer Maximalbestellmenge abhängig zu machen.

(3) Sie sind nicht berechtigt, gegenüber unseren Forderungen aufzurechnen, es sei denn, Ihre Gegenansprüche sind rechtskräftig festgestellt oder unbestritten. Sie sind zur Aufrechnung gegenüber unseren Forderungen auch berechtigt, wenn Sie Mängelrügen oder Gegenansprüche aus demselben Kauf- oder Dienstleistungsvertrag geltend machen.

(4) Als Käufer dürfen Sie ein Zurückbehaltungsrecht nur dann ausüben, wenn Ihr Gegenanspruch aus demselben Kaufvertrag bzw. Dienstleistungsvertrag herrührt.

§ 7 Eigentumsvorbehalt
(1) Die gelieferte Ware bleibt bis zur vollständigen Bezahlung des Kaufpreises in unserem Eigentum.

(2) Der Kunde ist zur Weiterveräußerung von uns unter Eigentumsvorbehalt gelieferten Waren im Rahmen des ordnungsgemäßen Geschäftsgangs berechtigt, wenn er sich das Eigentum an der von uns unter Eigentumsvorbehalt gelieferten Ware vorbehält. Der Kunde tritt uns hierzu bereits jetzt alle Forderungen aus einer Weiterveräußerung der von uns unter Eigentumsvorbehalt gelieferten Ware und aus dem von ihm vereinbarten Eigentumsvorbehalt zur Sicherung unserer Forderung aus der Geschäftsverbindung ab. Wir nehmen diese Abtretung an. Auf unser Verlangen ist der Kunde verpflichtet, die Abtretung seinem Abnehmer zur Zahlung an uns anzuzeigen.

(3) Der Kunde ist insbesondere nicht berechtigt, die von uns unter Eigentumsvorbehalt gelieferte Ware zu verpfänden bzw. im Rahmen einer Sicherungsübereignung zu übertragen.

(4) Bei vertragswidrigen Verhalten des Kunden, insbesondere bei Zahlungsverzug, sind wir zur Rücknahme der von uns unter Eigentumsvorbehalt gelieferten Ware nach Mahnung und Rücktritt vom Vertrag berechtigt und der Kunde zur Herausgabe verpflichtet. Ein Antrag auf Eröffnung des Insolvenzverfahrens über das Vermögen des Kunden berechtigt uns sofort die sofortige Rückgabe der von uns gelieferten Ware zu verlangen.

§ 8 Gewährleistung
(1) Liegt ein Mangel an Lieferung oder Leistungen von uns vor, werden wir nach unserer Wahl unentgeltlich nachbessern oder neu liefern („Nacherfüllung"), sofern der Mangel bereits im Zeitpunkt des Gefahrübergangs vorlag. Wir haften für Sach- oder Rechtsmängel gelieferter Artikel bzw. Werkleistungen nach den geltenden gesetzlichen Vorschriften, insbesondere § 434 ff. bzw. §§ 633 ff. BGB.

(2) Die Verjährungsfrist für gesetzliche Mängelansprüche bei neuen Sachen beträgt für den Verbrauchsgüterkauf zwei Jahre, ansonsten beim Kauf- und Werklieferungsvertrag 12 Monate. Die Verjährung beginnt nach Ablieferung des Liefergegenstandes - bzw. wenn dies vereinbart ist – nach Inbetriebnahme des Liefergegenstandes oder der Abnahme der Leistung.

(3) Die Verjährungsfrist für gesetzliche Mängelansprüche bei gebrauchten Liefergegenständen, ausgenommen neuwertige und neuwertig aufgearbeitete Teile, beträgt beim Kauf- und Werklieferungsvertrag ein Jahr und beginnt mit der Ablieferung der Sache bzw. – wenn dies vereinbart ist – nach Inbetriebnahme des Liefergegenstandes oder Abnahme der Leistung.

(4) Etwaige von uns gegebene Verkäufergarantien für bestimmte Artikel oder von den Herstellern bestimmter Artikel eingeräumte Herstellergarantien treten neben die Ansprüche wegen Sach- und Rechtsmängel im Sinne von Abs.1. Einzelheiten des Umfangs solcher Garantien ergeben sich aus den Garantiebedingungen, die den Artikeln gegebenenfalls beiliegen.

(5) Etwaige Rückgriffsansprüche des Kunden im Falle eines Verbrauchsgüterkaufes gemäß §§ 478, 479 BGB bleiben unberührt, bestehen aber nur insoweit, als der Kunde mit seinem Abnehmer keine über die gesetzlichen Mängelansprüche hinausgehende Vereinbarung getroffen hat.

§ 9 Haftung
(1) Wir haften Ihnen gegenüber in allen Fällen vertraglicher und außervertraglicher Haftung bei Vorsatz und grober Fahrlässigkeit nach Maßgabe der gesetzlichen Bestimmungen auf Schadensersatz oder Ersatz vergeblicher Aufwendungen.

(2) In sonstigen Fällen haften wir – soweit in Abs.3 nicht abweichend geregelt – nur bei Verletzung einer Vertragspflicht, deren Erfüllung die ordnungsgemäße Durchführung des Vertrags überhaupt erst ermöglicht und auf deren Einhaltung Sie als Kunde regelmäßig vertrauen dürfen (so genannte Kardinalpflichten), und zwar beschränkt auf Ersatz des vorhersehbaren und typischen Schadens. In allen übrigen Fällen ist unsere Haftung vorbehaltlich der Regelung in Abs.3 ausgeschlossen.

(3) Unsere Haftung für Schäden aus der Verletzung des Lebens, des Körpers oder der Gesundheit und nach dem Produkthaftungsgesetz bleibt von den vorstehenden Haftungsbeschränkungen und -ausschlüssen unberührt.

§ 10 Urheberrechte
Wir haben an allen Bildern, Filmen und Texten, die in unserem Produktportfolio und im Rahmen unserer Schulungen veröffentlicht werden, Urheberrechte. Eine Verwendung der Bilder, Filme, und Texte, ist ohne unsere ausdrückliche Zustimmung nicht gestattet. Überlassene Schulungsunterlagen und Dokumente sind an die jeweiligen Teilnehmer gebunden und dürfen insbesondere nicht vervielfältigt oder veröffentlich werden. Die Unterlagen dienen dem Teilnehmer zur eigenen Dokumentation der besuchten Veranstaltung. Darüberhinausgehende Nutzungsrechte bestehen nicht. Schulungsunterlagen und Dokumente, die von den externen Referenten zur Verfügung gestellt werden, liegen in der Verantwortung des jeweiligen Erstellers.

§ 11 Schulungen
(1) Stornierungen und Absagen Eine Stornierung der Anmeldung ist nur schriftlich möglich Erfolgt die Stornierung bis zwei Wochen vor Veranstaltungsbeginn, so wird die Teilnahmegebühr abzüglich 15 % des Gesamtbetrages zurückerstattet, danach wird die Teilnahmegebühr in voller Höhe erhoben. Bei Nichtteilnahme wird die Teilnahmegebühr in voller Höhe in Rechnung gestellt. Entscheidend ist der Eingang der Stornierungserklärung bei uns. Ein Ersatzteilnehmer kann jederzeit kostenfrei benannt werden. Eine Umbuchung ist bis zu einer Woche vor Veranstaltungsbeginn kostenfrei möglich.

(2) Schulungsendgeld Das Schulungsendgeld versteht sich pro Teilnehmer. Reise- und Hotelkosten sind nicht im Preis enthalten. Eine Teilnahme an nur einem Teil der gebuchten Veranstaltung berechtigt nicht zur Preisminderung. Die Preise verstehen sich zuzüglich der geltenden Umsatzsteuer, die in der Rechnung gesondert ausgewiesen wird. Zahlungen sind spätestens 14 Tage nach Rechnungsdatum ohne Abzug, unter Angabe der Rechnungsnummer, auf das auf der Rechnung angegebene Konto zu überweisen.

(3) Teilnehmerzahl Die Teilnehmerzahl der Schulungen ist begrenzt. Anmeldungen werden daher in der Reihenfolge des Eingangs der schriftlichen Anmeldungen berücksichtigt. Sollte die Teilnahme wegen Überbelegung nicht möglich sein, wird der Kunde hierüber unverzüglich in Kenntnis gesetzt. Reinhold Medizintechnik behält sich vor, Schulungen wegen besonderer Gründe oder mangels ausreichender Beteiligung spätestens zehn Werktage vor Schulungsbeginn zu verschieben, abzusagen oder mit anderen Veranstaltungen zusammenzulegen. In diesem Falle erhält der Teilnehmer umgehend eine Benachrichtigung. Weiter steht dem Teilnehmer in diesen Fällen ein Rücktrittsrecht zu. Weitergehende Ansprüche, insbesondere auf Aufwendungsersatz (Stornogebühren für gebuchte Anreise oder Hotel), bestehen nicht. Der Verkäufer ist berechtigt, in begründeten Fällen die Veranstaltung von anderen, als den angegebenen Referenten durchführen zu lassen.

§ 12 Datenschutzhinweis
Wir erheben, verarbeiten und nutzen Ihre personenbezogenen Daten, insbesondere Ihre Kontaktdaten zur Abwicklung Ihrer Bestellung, so auch Ihre E-Mail-Adresse, wenn Sie uns diese angeben. Zur Bonitätsprüfung können wir Informationen (z.B. auch einen sogenannten Score-Wert von externen Dienstleistern zur Entscheidungshilfe heranziehen und davon die Zahlungsart abhängig machen Zu den Informationen gehören auch Informationen über Ihre Anschrift. Näheres entnehmen Sie Bitte unseren Datenschutzbestimmungen, die Sie unter https://www.reinhold-medizintechnik.de/datenschutz.html finden.

§ 13 Sicherheitsbestimmungen
(1) Der Kunde ist für die Einhaltung der ihn verpflichtenden nationalen Gesetze, Verordnungen und sicherheitsrechtlichen Vorschriften, insbesondere im Hinblick auf Zulassung, Installation, Betrieb, Wartung und Reparatur der Liefergegenstände verantwortlich und verpflichtet, diese zu erfüllen. So sind insbesondere bei Inbetriebnahme eines Gerätes die Vorschriften des Medizinproduktgesetzes (MPG) sowie der Medizinproduktbetreiberverordnung (MPBetreibV) einzuhalten und zuvor, soweit vorgeschrieben, eine sicherheitstechnische Kontrolle (STK) des Gerätes durchzuführen.

(2) Der Kunde ist verpflichtet, Reinhold Medizintechnik von allen Ansprüchen, die gegen Reinhold Medizintechnik aufgrund der Nichtbeachtung derartiger Vorschriften durch den Kunden geltend gemacht werden, freizustellen.

§ 14 Behinderung der Ausführung
(1) Der Kunde hat dafür Sorge zu tragen, dass bei anfallenden Wartungsarbeiten durch uns notwendige Gerätelisten vor Prüfung rechtzeitig vorgelegt werden, so dass die Prüfung der Geräte innerhalb angemessener Zeit ungehindert erfolgen kann.

(2) Fehler sind bei Reparaturanfragen konkret zu bezeichnen.

(3) Zudem ist unser Techniker soweit zu unterstützen, dass ihm die zu prüfenden Geräte zur Verfügung gestellt werden. Zudem ist dem Techniker ausreichend Platz zum Prüfen und Reparieren der Geräte zu schaffen. Der Kunde muss rechtzeitig für alle erforderlichen Abstimmungen und Unterrichtungen hinsichtlich des technischen und zeitlichen Arbeitsablaufes sorgen. Er hat einen Ansprechpartner zu benennen.

§ 15 Anwendbares Recht und Gerichtsstand
(1) Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts.

(2) Wenn Sie die Bestellung als Verbraucher abgegeben haben und zum Zeitpunkt Ihrer Bestellung Ihren gewöhnlichen Aufenthalt in einem anderen Land haben, bleibt die Anwendung zwingender Rechtsvorschriften des Landes von der in Absatz 1 getroffenen Rechtswahl unberührt.

- Ende der Allgemeinen Geschäftsbedingungen`}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}