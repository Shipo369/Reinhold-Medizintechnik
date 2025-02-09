import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft } from 'lucide-react';

export function Privacy() {
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
              <h1 className="text-2xl font-bold text-gray-900">Datenschutzerklärung</h1>
            </div>
          </div>

          <div className="p-6">
            <div className="prose max-w-none text-gray-700 whitespace-pre-wrap">
              {`Das Recht des Einzelnen, grundsätzlich selbst über die Preisgabe und Verwendung seiner personenbezogenen Daten zu bestimmen (Recht auf informationelle Selbstbestimmung) ist uns wichtig. Daher erfolgt die Datenverarbeitung nach den gesetzlichen Vorgaben.

Die rechtlichen Grundlagen für die Verarbeitung von Daten findet sich u.a. in der europäischen Datenschutzgrundverordnung (DSGVO), dem Bundesdatenschutzgesetz (BDSG-neu) und weiteren Gesetzen, die sich mit der Erfassung und Verarbeitung von personenbezogenen Daten beschäftigen. Weitere nützliche Hinweise finden Sie hierzu auf der Website des Bundesbeauftragten für den Datenschutz und Informationsfreiheit unter https://www.bfdi.bund.de/DE/Home/home_node.html der Aufsichtsbehörde, der Landesbeauftragte für Datenschutz und Informationsfreiheit Nordrhein-Westfalens (LDI NRW) unter https://www.ldi.nrw.de/. Die Postanschrift lautet wie folgt:

Landesbeauftragte für Datenschutz und Informationsfreiheit
Nordrhein-Westfalen
Postfach 20 04 44
40102 Düsseldorf
Tel.: 0211/38424-0
Fax: 0211/38424-10
E-Mail: poststelle@ldi.nrw.de

1. Verantwortlicher
Verantwortlicher im Sinne der Datenschutzgrundverordnung ist gemäß Art. 4 Nr. 7 DS-GVO: Reinhold Medizintechnik GmbH

vertreten durch Geschäftsführer: Markus Reinhold
Möhnestraße 55
D-59755 Arnsberg
Fon: +49(0) 2932 429 2030
Fax: +49(0) 2932 429 2032
E-Mai-Adresse: info@reinhold-medizintechnik.de
im nachfolgenden Reinhold Medizintechnik GmbH genannt.

Sie haben zudem, wenn wir Ihr Anliegen aus Ihrer Sicht nicht angemessen behandeln u.a. (Unbeschadet eines anderweitigen verwaltungsrechtlichen oder gerichtlichen Rechtsbehelfs) ein Beschwerderecht bei der für den Datenschutz zuständigen Aufsichtsbehörde, insbesondere in dem Mitgliedstaat ihres Aufenthaltsorts, ihres Arbeitsplatzes oder des Orts des mutmaßlichen Verstoßes.

2. Hintergrund der Datenschutzerklärung
Die nachfolgende Datenschutzerklärung soll darüber informieren, welche Daten bei dem Besuch der Website unseres Unternehmens Reinhold Medizintechnik, einer Kontaktaufnahme und im Falle eines Vertragsabschlusses erhoben, gespeichert und verarbeitet werden. Zudem wird über Rechte informiert, die dem Betroffenen im Zusammenhang mit der Datenerhebung zustehen.

Es geht um den Schutz „personenbezogener Daten". Hierunter versteht man alle Informationen, die sich auf eine identifizierte oder identifizierbare natürliche Person (im Folgenden „betroffene Person") beziehen. Für die Identifizierbarkeit ist nicht unbedingt eine Namensangabe erforderlich. Es reicht aus, dass z.B. mittels Zuordnung einer Kennnummer, einer IP-Adresse oder sonstiger Merkmale, Rückschlüsse auf eine Person und ihrer Identität ermöglichen. Hierunter fällt natürlich auch Ihr Name, Ihre Telefonnummer, Ihre E-Mail-Adresse und Anschrift, sowie andere Daten, die uns übermittelt werden.

3. Welche Daten werden erhoben
Welche Daten erhoben werden, hängt davon ab, in welcher Form Sie den Kontakt zu uns aufnehmen:

a.) Beim Besuch der Website

Beim Aufrufen unserer Website „www.reinhold-medizintechnik.de" werden durch den auf Ihrem Endgerät zum Einsatz kommenden Browser automatisch Informationen an den Server unserer Website gesendet. Diese Informationen werden temporär in einem sog. Logfile gespeichert. Folgende Informationen werden dabei ohne Ihr Zutun erfasst und bis zur automatisierten Löschung gespeichert:

IP-Adresse des anfragenden Rechners,
Datum und Uhrzeit des Zugriffs,
Name und URL der abgerufenen Datei,
Website, von dem der Zugriff erfolgt (Referrer-URL),
verwendeter Browser und ggf. das Betriebssystem Ihres Rechners sowie der Name Ihres Access-Providers.

Die genannten Daten werden durch uns zu folgenden Zwecken verarbeitet:

Gewährleistung eines reibungslosen Verbindungsaufbaus der Website,
Gewährleistung einer komfortablen Nutzung unserer Website,
Auswertung der Systemsicherheit und -stabilität sowie
zu weiteren administrativen Zwecken.

Die Rechtsgrundlage für die Datenverarbeitung ist Art. 6 Abs. 1 S. 1 lit. f DSGVO. Unser berechtigtes Interesse folgt aus oben aufgelisteten Zwecken zur Datenerhebung. In keinem Fall verwenden wir die erhobenen Daten zu dem Zweck, Rückschlüsse auf Ihre Person zu ziehen.

b.) Bei Nutzung unseres Kontaktformulars

Bei Fragen jeglicher Art bieten wir Ihnen die Möglichkeit, mit uns über ein auf der Website bereitgestelltes Formular Kontakt aufzunehmen.

Ebenso können Sie z.B. auch direkt über E-Mail mit uns Kontakt aufnehmen. Damit wir Ihr Anliegen bearbeiten können, werden Ihre Kontaktdaten sowie Ihr Anliegen gespeichert. Wenn es um die Anbahnung eines Vertrages geht, ist die Angabe einer gültigen E-Mail-Adresse erforderlich, damit wir wissen, von wem die Anfrage stammt, um diese ordnungsgemäß bearbeiten zu können. Bei sonstigen Fragen können Sie auch ein Pseudonym angeben.

Die Datenverarbeitung zum Zwecke der Kontaktaufnahme mit uns erfolgt nach Art. 6 Abs. 11 lit. a DSGVO auf Grundlage Ihrer freiwillig erteilten Einwilligung. Die für die Benutzung des Kontaktformulars von uns erhobenen personenbezogenen Daten werden nach Erledigung der von Ihnen gestellten Anfrage automatisch gelöscht, soweit keine Aufbewahrungspflichten entgegenstehen und die Angelegenheit endgültig erledigt ist.

5. Weitergabe von Daten
Eine Übermittlung Ihrer persönlichen Daten an Dritte zu anderen als den im Folgenden aufgeführten Zwecken findet nicht statt.

Wir geben Ihre persönlichen Daten nur an Dritte weiter, wenn:

Sie Ihre nach Art. 6 Abs. 1 S. 1 lit. a DSGVO ausdrückliche Einwilligung dazu erteilt haben,
die Weitergabe nach Art. 6 Abs. 1 S. 1 lit. f DSGVO zur Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen erforderlich ist und kein Grund zur Annahme besteht, dass Sie ein überwiegendes schutzwürdiges Interesse an der Nichtweitergabe Ihrer Daten haben,
für den Fall, dass für die Weitergabe nach Art. 6 Abs. 1 S. 1 lit. c DSGVO eine gesetzliche Verpflichtung besteht, sowie
dies gesetzlich zulässig und nach Art. 6 Abs. 1 S. 1 lit. b DSGVO für die Abwicklung von Vertragsverhältnissen mit Ihnen erforderlich ist.

6. Cookies
Wir setzen auf unserer Website Cookies ein. Hierbei handelt es sich um kleine Dateien, die Ihr Browser automatisch erstellt und die auf Ihrem Endgerät (Laptop, Tablet, Smartphone o.ä.) gespeichert werden, wenn Sie unsere Seite besuchen. Cookies richten auf Ihrem Endgerät keinen Schaden an, enthalten keine Viren, Trojaner oder sonstige Schadsoftware.

In dem Cookie werden Informationen abgelegt, die sich jeweils im Zusammenhang mit dem spezifisch eingesetzten Endgerät ergeben. Dies bedeutet jedoch nicht, dass wir dadurch unmittelbar Kenntnis von Ihrer Identität erhalten.

Der Einsatz von Cookies dient einerseits dazu, die Nutzung unseres Angebots für Sie angenehmer zu gestalten. So setzen wir sogenannte Session-Cookies ein, um zu erkennen, dass Sie einzelne Seiten unserer Website bereits besucht haben. Diese werden nach Verlassen unserer Seite automatisch gelöscht.

Darüber hinaus setzen wir ebenfalls zur Optimierung der Benutzerfreundlichkeit temporäre Cookies ein, die für einen bestimmten festgelegten Zeitraum auf Ihrem Endgerät gespeichert werden. Besuchen Sie unsere Seite erneut, um unsere Dienste in Anspruch zu nehmen, wird automatisch erkannt, dass Sie bereits bei uns waren und welche Eingaben und Einstellungen sie getätigt haben, um diese nicht noch einmal eingeben zu müssen.

Zum anderen setzen wir Cookies ein, um die Nutzung unserer Website statistisch zu erfassen und zum Zwecke der Optimierung unseres Angebotes für Sie auszuwerten (siehe dazu Ziff.

Diese Cookies ermöglichen es uns, bei einem erneuten Besuch unserer Seite automatisch zu erkennen, dass Sie bereits bei uns waren. Diese Cookies werden nach einer jeweils definierten Zeit automatisch gelöscht.

Die durch Cookies verarbeiteten Daten sind für die genannten Zwecke zur Wahrung unserer berechtigten Interessen sowie der Dritter nach Art. 6 Abs. 1 S. 1 lit. f DSGVO erforderlich.

Die meisten Browser akzeptieren Cookies automatisch. Sie können Ihren Browser jedoch so konfigurieren, dass keine Cookies auf Ihrem Computer gespeichert werden oder stets ein Hinweis erscheint, bevor ein neuer Cookie angelegt wird. Die vollständige Deaktivierung von Cookies kann jedoch dazu führen, dass Sie nicht alle Funktionen unserer Website nutzen können.

7. Analyse-Tools
Hierunter versteht man Verfahren für die Datenauswertung im Internet. Im Onlinemarketing kann der Betreiber einer Website damit überprüfen, welcher Anteil des Besucherstroms über einzelne Maßnahmen auf die eigene Website gelangt ist und welche Aktionen dort durch die Nutzer ausgelöst wurden. Es gibt unterschiedliche Tools, mit denen Aktivitäten analysiert werden. Die hier verwendeten Tools sind:

a) Tracking-Tools
Die von uns eingesetzten Tracking-Maßnahmen werden auf Grundlage des Art. 6 Abs. 1 S. 1 lit. f DSGVO durchgeführt. Mit den zum Einsatz kommenden Tracking-Maßnahmen wollen wir eine bedarfsgerechte Gestaltung und die fortlaufende Optimierung unserer Webseite sicherstellen. Zum anderen setzen wir die Tracking-Maßnahmen ein, um die Nutzung unserer Webseite statistisch zu erfassen und zum Zwecke der Optimierung unseres Angebotes für des Kunden auszuwerten. Diese Interessen sind als berechtigt im Sinne der vorgenannten Vorschrift anzusehen.

Die jeweiligen Datenverarbeitungszwecke und Datenkategorien sind aus den entsprechenden Tracking-Tools zu entnehmen.

aa) Google Analytics 1

Zum Zwecke der bedarfsgerechten Gestaltung und fortlaufenden Optimierung unserer Seiten nutzen wir Google Analytics, ein Webanalysedienst der Google Inc. (https://www.google.de/ intl/de/about/) (1600 Amphitheatre Parkway, Mountain View, CA 94043, USA; im Folgfenden „Google"). In diesem Zusammenhang werden pseudonymisierte Nutzungsprofile erstellt und Cookies (siehe dazu Ziffer 4) verwendet. Die durch die Cookies erzeugten Informationen über Ihre Benutzung dieser Website wie

Browser-Typ/-Version,
verwendetes Betriebssystem,
Referrer-URL (die zuvor besuchte Seite),
Hostname des zugreifenden Rechners (IP-Adresse),
Uhrzeit der Serveranfrage,

werden an einen Server von Google in den USA übertragen und dort gespeichert. Die Informationen werden verwendet, um die Nutzung der Website auszuwerten, um Reports über die Websiteaktivitäten zusammenzustellen und um weitere mit der Websitenutzung und der Internetnutzung verbundene Dienstleistungen zu Zwecken der Marktforschung und bedarfsgerechten Gestaltung dieser Internetseiten zu erbringen. Auch werden diese Informationen gegebenenfalls an Dritte übertragen, sofern dies gesetzlich vorgeschrieben ist oder soweit Dritte diese Daten im Auftrag verarbeiten. Es wird in keinem Fall Ihre IP-Adresse mit anderen Daten von Google zusammengeführt. Die IP-Adressen werden anonymisiert, so dass eine Zuordnung nicht möglich ist (IP-Masking).

Sie können die Installation der Cookies durch eine entsprechende Einstellung der Browser-Software verhindern; wir weisen jedoch darauf hin, dass in diesem Fall gegebenenfalls nicht sämtliche Funktionen dieser Website vollumfänglich genutzt werden können.

Sie können darüber hinaus die Erfassung der durch das Cookie erzeugten und auf Ihre Nutzung der Website bezogenen Daten (inkl. Ihrer IP-Adresse) sowie die Verarbeitung dieser Daten durch Google verhindern, indem Sie ein Browser-Add-on herunterladen und installieren (https://tools.google.com/dlpage/gaoptout?hl=de).

Alternativ zum Browser-Add-on, insbesondere bei Browsern auf mobilen Endgeräten, können Sie die Erfassung durch Google Analytics zudem verhindern, indem Sie auf diesen Link klicken. Es wird ein Opt-out-Cookie gesetzt, das die zukünftige Erfassung Ihrer Daten beim Besuch dieser Website verhindert. Der Opt-out-Cookie gilt nur in diesem Browser und nur für unsere Website und wird auf Ihrem Gerät abgelegt. Löschen Sie die Cookies in diesem Browser, müssen Sie das Opt-out-Cookie erneut setzen.

Weitere Informationen zum Datenschutz im Zusammenhang mit Google Analytics finden Sie etwa in der Google Analytics-Hilfe (https://support.google.com/analytics/answer/6004245?hl=de).

Datenschutzbehörden verlangen für den zuverlässigen Einsatz von Google-Analytics den Abschluss einer Auftragsdatenverarbeitungs-Vereinbarung. Eine entsprechende Vorlage wird unter http://www.google.com/analytics/terms/de.pdf von Google angeboten.

bb) Google Adwords Conversion Tracking

Um die Nutzung unserer Webseite statistisch zu erfassen und zum Zwecke der Optimierung unserer Website für Sie auszuwerten, nutzen wir ferner das Google Conversion Tracking. Dabei wird von Google Adwords ein Cookie (siehe dazu Ziffer 4) auf Ihrem Rechner gesetzt, sofern Sie über eine Google-Anzeige auf unsere Webseite gelangt sind.

Diese Cookies verlieren nach 30 Tagen ihre Gültigkeit und dienen nicht der persönlichen Identifizierung. Besucht der Nutzer bestimmte Seiten der Webseite des Adwords-Kunden und das Cookie ist noch nicht abgelaufen, können Google und der Kunde erkennen, dass der Nutzer auf die Anzeige geklickt hat und zu dieser Seite weitergeleitet wurde.

Jeder Adwords-Kunde erhält ein anderes Cookie. Cookies können somit nicht über die Webseiten von Adwords-Kunden nachverfolgt werden. Die mithilfe des Conversion-Cookies eingeholten Informationen dienen dazu, Conversion-Statistiken für Adwords-Kunden zu erstellen, die sich für Conversion-Tracking entschieden haben. Die Adwords-Kunden erfahren die Gesamtanzahl der Nutzer, die auf ihre Anzeige geklickt haben und zu einer mit einem Conversion-TrackingTag versehenen Seite weitergeleitet wurden. Sie erhalten jedoch keine Informationen, mit denen sich Nutzer persönlich identifizieren lassen.

Wenn Sie nicht an dem Tracking-Verfahren teilnehmen möchten, können Sie auch das hierfür erforderliche Setzen eines Cookies ablehnen – etwa per Browser-Einstellung, die das automatische Setzen von Cookies generell deaktiviert. Sie können Cookies für Conversion-Tracking auch deaktivieren, indem Sie Ihren Browser so einstellen, dass Cookies von der Domain „www.googleadservices.com" blockiert werden. Googles Datenschutzbelehrung zum Conversion-Tracking finden Sie unter (https://services.google.com/sitestats/de.html).

b) Contao
Wir verwenden die Open-Source-Software Contao zur Analyse und statistischen Auswertung der Nutzung der Website. Hierzu werden Cookies eingesetzt (siehe dazu Ziffer 6). Die durch die Cookies erzeugten Informationen über die Websitenutzung werden an unsere Server übertragen und in pseudonymen Nutzungsprofilen zusammengefasst. Die Informationen werden verwendet, um die Nutzung der Website auszuwerten und um eine bedarfsgerechte Gestaltung unserer Website zu ermöglichen. Eine Weitergabe der Informationen an Dritte erfolgt nicht.

Es wird in keinem Fall die IP-Adresse mit anderen den Nutzer betreffenden Daten in Verbindung gebracht. Die IP-Adressen werden anonymisiert, so dass eine Zuordnung nicht möglich ist (IP-Masking).

8. Betroffenenrechte
Sie haben das Recht:

gemäß Art.15 DSGVO Auskunft über Ihre von uns verarbeiteten personenbezogenen Daten zu verlangen. Insbesondere können Sie Auskunft über die Verarbeitungszwecke, die Kategorie der personenbezogenen Daten, die Kategorien von Empfängern, gegenüber denen Ihre Daten offengelegt wurden oder werden, die geplante Speicherdauer, das Bestehen eines Rechts auf Berichtigung, Löschung, Einschränkung der Verarbeitung oder Widerspruch, das Bestehen eines Beschwerderechts, die Herkunft ihrer Daten, sofern diese nicht bei uns erhoben wurden, sowie über das Bestehen einer automatisierten Entscheidungsfindung einschließlich Profiling und ggf. aussagekräftigen Informationen zu deren Einzelheiten verlangen; gemäß Art. 16 DSGVO unverzüglich die Berichtigung unrichtiger oder Vervollständigung Ihrer bei uns gespeicherten personenbezogenen Daten zu verlangen; gemäß Art. 17 DSGVO die Löschung Ihrer bei uns gespeicherten personenbezogenen Daten zu verlangen, soweit nicht die Verarbeitung zur Ausübung des Rechts auf freie Meinungsäußerung und Information, zur Erfüllung einer rechtlichen Verpflichtung, aus Gründen des öffentlichen Interesses oder zur Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen erforderlich ist; gemäß Art. 18 DSGVO die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen, soweit die Richtigkeit der Daten von Ihnen bestritten wird, die Verarbeitung unrechtmäßig ist, Sie aber deren Löschung ablehnen und wir die Daten nicht mehr benötigen, Sie jedoch diese zur Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen benötigen oder Sie gemäß Art. 21 DSGVO Widerspruch gegen die Verarbeitung eingelegt haben; gemäß Art. 20 DSGVO Ihre personenbezogenen Daten, die Sie uns bereitgestellt haben, in einem strukturierten, gängigen und maschinenlesebaren Format zu erhalten oder die Übermittlung an einen anderen Verantwortlichen zu verlangen; gemäß Art. 7 Abs. 3 DSGVO Ihre einmal erteilte Einwilligung jederzeit gegenüber uns zu widerrufen. Dies hat zur Folge, dass wir die Datenverarbeitung, die auf dieser Einwilligung beruhte, für die Zukunft nicht mehr fortführen dürfen und gemäß Art. 77 DSGVO sich bei einer Aufsichtsbehörde zu beschweren. In der Regel können Sie sich hierfür an die Aufsichtsbehörde Ihres üblichen Aufenthaltsortes oder Arbeitsplatzes oder unseres Unternehmenssitzes wenden.

9. Widerspruchsrecht
Sofern Ihre personenbezogenen Daten auf Grundlage von berechtigten Interessen gemäß Art. 6 Abs. 1 S. 1 lit. f DSGVO verarbeitet werden, haben Sie das Recht, gemäß Art. 21 DSGVO Widerspruch gegen die Verarbeitung Ihrer personenbezogenen Daten einzulegen, soweit dafür Gründe vorliegen, die sich aus Ihrer besonderen Situation ergeben oder sich der Widerspruch gegen Direktwerbung richtet. Im letzteren Fall haben Sie ein generelles Widerspruchsrecht, das ohne Angabe einer besonderen Situation von uns umgesetzt wird.

Möchten Sie von Ihrem Widerrufs- oder Widerspruchsrecht Gebrauch machen, genügt eine E-Mail an info@reinhold-medizintechnik.de.

10. Löschung und Sperrung
Die Speicherung Ihrer personenbezogenen Daten erfolgt bis zur Erreichung der angegebenen Zwecke bzw. solange wir ein berechtigtes Interesse an der Speicherung haben.

Danach erfolgt eine Löschung, soweit keine anderweitigen Abreden mit Ihnen getroffen wurden oder gesetzliche Archivierungspflichten bestehen, wie zum Beispiel gegenüber dem Finanzamt. Bei einer gesetzlich veranlassten Archivierung werden die Daten für sonstige Zugriffe gesperrt. Diese Unterlagen werden nach Ablauf der gesetzlichen Aufbewahrungsfristen im Rahmen regelmäßiger Aktionen datenschutzgerecht gelöscht und vernichtet.

Wenn Sie in eine Erhebung, Verarbeitung und Nutzung Ihrer Daten eingewilligt haben, speichern und nutzen wir Ihre Daten auf unbestimmte Zeit bis zu einem Widerruf oder Wegfall des Zwecks zu dem Sie die Einwilligung erteilt haben. Danach erfolgt eine Archivierung d. Einwilligung u. Verarbeitungsdaten bis zur Verjährung (regelmäßig drei Jahre) für Rechtsverteidigungszwecke (Rechtsgrundlage Art. 17 Abs. 3 lit. e DSGVO).

Wenn Sie von uns keine Werbung mehr wünschen, nutzen wir Ihren Namen, die Adresse und ggf. die E-Mailadresse für Zwecke der Sperrung in entsprechenden Listen, mit denen wir unsere Werbemaßnahmen abgleichen, damit Sie keine weitere Werbung mehr erhalten. Löschen in diesem Sinn bedeutet also zunächst, dass Ihre Daten insbesondere für Werbung und Marketingaktivitäten in unseren Systemen gesperrt werden (Rechtsgrundlage Art. 6 Abs.1 lit. f DSGVO). Die Daten werden – soweit erforderlich – weiterhin für andere Zwecke als Werbung verarbeitet, etwa im Rahmen der Vertragsabwicklung und ggf. Gewährleistung sowie handelsrechtlichen und steuerrechtlichen Dokumentation (Rechtsgrundlage Art. 6 Abs. 1 lit b u. c DSGVO).

11. Datensicherheit
Wir verwenden innerhalb des Website-Besuchs das verbreitete SSL-Verfahren (Secure Socket Layer) in Verbindung mit der jeweils höchsten Verschlüsselungsstufe, die von Ihrem Browser unterstützt wird. In der Regel handelt es sich dabei um eine 256 Bit Verschlüsselung. Falls Ihr Browser keine 256-Bit Verschlüsselung unterstützt, greifen wir stattdessen auf 128-Bit v3 Technologie zurück. Ob eine einzelne Seite unseres Internetauftrittes verschlüsselt übertragen wird, erkennen Sie an der geschlossenen Darstellung des Schüssel- beziehungsweise Schloss-Symbols in der unteren Statusleiste Ihres Browsers. Wir bedienen uns im Übrigen geeigneter technischer und organisatorischer Sicherheitsmaßnahmen, um Ihre Daten gegen zufällige oder vorsätzliche Manipulationen, teilweisen oder vollständigen Verlust, Zerstörung oder gegen den unbefugten Zugriff Dritter zu schützen. Unsere Sicherheitsmaßnahmen werden entsprechend der technologischen Entwicklung fortlaufend verbessert.

12. Aktualität und Änderung dieser Datenschutzerklärung
Diese Datenschutzerklärung ist aktuell gültig und hat den Stand Mai 2018. Durch die Weiterentwicklung unserer Website und Angebote darüber oder aufgrund geänderter gesetzlicher beziehungsweise behördlicher Vorgaben kann es notwendig werden, diese Datenschutzerklärung zu ändern. Die jeweils aktuelle Datenschutzerklärung kann jederzeit auf der Website unter https://www.reinhold-medizintechnik.de/datenschutz.html von Ihnen abgerufen und ausgedruckt werden.

Sie können dieses Dokument ausdrucken oder speichern, indem Sie die übliche Funktionalität Ihres Internetdienstprogram (=Browser: dort meist „Datei" -> „Speichern unter") nutzen. Sie können sich dieses Dokument auch in PDF-Form herunterladen und archivieren, indem Sie hier klicken. Zum Öffnen der PDF-Datei benötigen Sie das kostenfreie Programm Adobe Reader (unter www.adobe.de) oder vergleichbare Programme, die das PDF-Format beherrschen.`}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}