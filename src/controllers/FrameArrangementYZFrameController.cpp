#include "FrameArrangementYZFrameController.h"
#include "FrameArrangementYZController.h"
#include <QPainter>
#include <QPen>
#include <QMetaObject>
#include <QDebug>
#include <QJsonObject>
#include <QJsonArray>
#include <cmath>

FrameArrangementYZFrameController::FrameArrangementYZFrameController(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_gridSpacing(20)
    , m_currentFrameNo(-1)
    , m_controller(nullptr)
    , m_greenLineColor(Qt::green)
    , m_scaleFactor(1.0)
    , m_panX(0.0)
    , m_panY(0.0)
{
    setRenderTarget(QQuickPaintedItem::FramebufferObject);
    setAntialiasing(true);
}

void FrameArrangementYZFrameController::paint(QPainter *painter)
{
    if (!painter) return;

    int w = static_cast<int>(width());
    int h = static_cast<int>(height());
    
    if (w <= 0 || h <= 0) return;

    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->fillRect(0, 0, w, h, Qt::white);

    // Calculate center coordinates
    int centerX = w / 2;
    int centerY = h / 2;

    // Apply view transform: pan then zoom, around the center (zoom about origin after translate)
    painter->save();
    // Translate by pan values
    painter->translate(m_panX, m_panY);
    // Zoom about the screen center: move origin to center, scale, then move back
    painter->translate(centerX, centerY);
    painter->scale(m_scaleFactor, m_scaleFactor);
    painter->translate(-centerX, -centerY);

    // Only draw frame lines based on table data - no default grid
    drawFrameLines(painter, centerX, centerY, m_gridSpacing);

    painter->restore();
}

void FrameArrangementYZFrameController::drawFrameLines(QPainter *p, int centerX, int centerY, int spacing)
{
    // Load current frame data
    loadFrameData();
    m_drawnLines.clear();
    
    // Get all data without frameNo filter
    QList<QJsonObject> allFrameData;
    for (auto val : m_frameYZDrawing) {
        if (val.isObject()) {
            allFrameData.append(val.toObject());
        }
    }
    
    qDebug() << "=== DEBUG DRAW FRAME LINES (Reference Logic) ===";
    qDebug() << "Total data available:" << allFrameData.size();
    
    if (allFrameData.isEmpty()) {
        qDebug() << "❌ No data available!";
        return;
    }

    // Draw center lines first (black solid line), infinite length using +/-99999*spacing extents
    QPen centerPen(Qt::black, 1, Qt::SolidLine);
    p->setPen(centerPen);
    // Vertical centerline (Z axis): from very top to very bottom
    p->drawLine(centerX, centerY - 99999 * spacing, centerX, centerY + 99999 * spacing);
    // Horizontal centerline (Y axis): from far left to far right
    p->drawLine(centerX - 99999 * spacing, centerY, centerX + 99999 * spacing, centerY);

    // Set pen for frame lines (use configured green color)
    QPen framePen(m_greenLineColor, 1);
    framePen.setCosmetic(true);
    p->setPen(framePen);

    // Process each entry using reference JavaScript logic
    for (const auto &entry : allFrameData) {
        qDebug() << "Processing entry:" << entry;
        
        if (!isValidFieldData(entry)) {
            qDebug() << "❌ Invalid field data";
            continue;
        }

        // Get values like reference JavaScript
        double yCoor = entry.value("y").toDouble();
        double zCoor = entry.value("z").toDouble();
        QString thisSym = entry.value("sym").toString();
        QString name = entry.value("name").toString();
        double entrySpacing = entry.value("spacing").toDouble();
        int lineCount = entry.value("no").toInt();

        qDebug() << "Y:" << yCoor << "Z:" << zCoor << "Sym:" << thisSym << "Count:" << lineCount << "Spacing:" << entrySpacing;

        // Determine initial offset rule when value equals 0: start from spacing (skip 0)
        bool yStartsAtZero = qFuzzyIsNull(yCoor);
        bool zStartsAtZero = qFuzzyIsNull(zCoor);

        // Draw multiple lines based on count (like reference)
        for (int i = 0; i < lineCount; ++i) {
            // Progressive spacing like reference, with zero rule applied per axis below
            double spacingInLoop = i * entrySpacing;

            // Check if Y is empty/not set and Z has value (including 0) - draws HORIZONTAL lines
            if (!hasYValue(entry) && hasZValue(entry)) {
                // If z==0, skip drawing at 0 by shifting first iteration by +spacing
                double effectiveSpacing = spacingInLoop + ((zStartsAtZero && i == 0) ? entrySpacing : 0.0);
                drawZCoordinateLines(p, centerX, centerY, spacing, zCoor, effectiveSpacing, thisSym, i);
            }
            // Check if Z is empty/not set and Y has value (including 0) - draws VERTICAL lines
            else if (!hasZValue(entry) && hasYValue(entry)) {
                // If y==0, skip drawing at 0 by shifting first iteration by +spacing
                double effectiveSpacing = spacingInLoop + ((yStartsAtZero && i == 0) ? entrySpacing : 0.0);
                drawYCoordinateLines(p, centerX, centerY, spacing, yCoor, effectiveSpacing, thisSym, i);
            }
        }
    }
    
    // Draw ship outline last so it stays clearly visible as boundary
    drawShipOutline(p, centerX, centerY, spacing);

    qDebug() << "=== END DEBUG ===";
}

// Draw ship outline: black rectangle centered at origin.
// Width total = 24384 (left/right half = 12192), Height total = 5490.
// Uses same mm->px scaling as lines: px = (mm/1000) * spacing.
void FrameArrangementYZFrameController::drawShipOutline(QPainter *p, int centerX, int centerY, int spacing)
{
    // Half-width in mm and full height in mm
    const double halfWidthMM = 24384.0 / 2.0; // 12192
    const double heightMM = 5490.0;

    // Convert to pixels based on grid spacing scale (1000 mm per spacing unit)
    const double scale = spacing / 1000.0;
    const int halfWidthPx = static_cast<int>(halfWidthMM * scale);
    const int halfHeightPx = static_cast<int>((heightMM / 2.0) * scale);

    // Points matching the JS reference (draw each side explicitly)
    const QPoint rightBottom(centerX + halfWidthPx, centerY - static_cast<int>(0 * scale));
    const QPoint rightTop(centerX + halfWidthPx, centerY - static_cast<int>(heightMM * scale));
    const QPoint leftBottom(centerX - halfWidthPx, centerY - static_cast<int>(0 * scale));
    const QPoint leftTop(centerX - halfWidthPx, centerY - static_cast<int>(heightMM * scale));

    QPen prev = p->pen();
    QPen outlinePen(Qt::black, 2, Qt::SolidLine);
    outlinePen.setCosmetic(true);
    p->setPen(outlinePen);

    // Right line
    p->drawLine(rightBottom, rightTop);
    // Top line
    p->drawLine(rightTop, leftTop);
    // Left line
    p->drawLine(leftBottom, leftTop);
    // Bottom line
    p->drawLine(leftBottom, rightBottom);

    p->setPen(prev);
}

// Draw Z coordinate lines (HORIZONTAL lines) - based on reference JavaScript
void FrameArrangementYZFrameController::drawZCoordinateLines(QPainter *p, int centerX, int centerY, int spacing, 
                                                           double zCoor, double spacingInLoop, const QString &thisSym, int index)
{
    qDebug() << "Drawing Z coordinate (HORIZONTAL) lines - zCoor:" << zCoor << "spacingInLoop:" << spacingInLoop << "sym:" << thisSym;

    // Calculate Y positions for horizontal lines (like reference JavaScript)
    int firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z;

    if (thisSym == "P") {
        // Define first point (left side)
        firstPoint_y = centerX + -99999 * spacing;
        firstPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Define second point (to center)
        secondPoint_y = centerX + 0 * spacing;
        secondPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Draw line
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew P side horizontal line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        // Record for hit testing
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), true, index, (zCoor + spacingInLoop), QStringLiteral("Y") });
    }
    else if (thisSym == "S") {
        // Define first point (from center)
        firstPoint_y = centerX + 0 * spacing;
        firstPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Define second point (right side)
        secondPoint_y = centerX + 99999 * spacing;
        secondPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Draw line
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew S side horizontal line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), true, index, (zCoor + spacingInLoop), QStringLiteral("Y") });
    }
    else if (thisSym == "P+S" || thisSym == "S+P") {
        // Define first point (full width)
        firstPoint_y = centerX + -99999 * spacing;
        firstPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Define second point (full width)
        secondPoint_y = centerX + 99999 * spacing;
        secondPoint_z = centerY - static_cast<int>((zCoor + spacingInLoop) / 1000.0 * spacing);

        // Draw line
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew P+S horizontal line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), true, index, (zCoor + spacingInLoop), QStringLiteral("Y") });
    }
}

// Draw Y coordinate lines (VERTICAL lines) - based on reference JavaScript  
void FrameArrangementYZFrameController::drawYCoordinateLines(QPainter *p, int centerX, int centerY, int spacing,
                                                           double yCoor, double spacingInLoop, const QString &thisSym, int index)
{
    qDebug() << "Drawing Y coordinate (VERTICAL) lines - yCoor:" << yCoor << "spacingInLoop:" << spacingInLoop << "sym:" << thisSym;

    // Calculate positions for vertical lines (like reference JavaScript)
    int firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z;

    if (thisSym == "P") {
        // Ensure yCoor is always negative for P side
        double yCoorNeg = -qAbs(yCoor + spacingInLoop);

        // Define first point (top)
        firstPoint_y = centerX + static_cast<int>(yCoorNeg / 1000.0 * spacing);
        firstPoint_z = centerY - -99999 * spacing;

        // Define second point (bottom)
        secondPoint_y = centerX + static_cast<int>(yCoorNeg / 1000.0 * spacing);
        secondPoint_z = centerY - 99999 * spacing;

        // Draw line
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew P side vertical line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), false, index, (yCoor + spacingInLoop), QStringLiteral("Z") });
    }
    else if (thisSym == "S") {
        // Ensure yCoor is always positive for S side
        double yCoorPos = qAbs(yCoor + spacingInLoop);

        // Define first point (top)
        firstPoint_y = centerX + static_cast<int>(yCoorPos / 1000.0 * spacing);
        firstPoint_z = centerY - -99999 * spacing;

        // Define second point (bottom)
        secondPoint_y = centerX + static_cast<int>(yCoorPos / 1000.0 * spacing);
        secondPoint_z = centerY - 99999 * spacing;

        // Draw line
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew S side vertical line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), false, index, (yCoor + spacingInLoop), QStringLiteral("Z") });
    }
    else if (thisSym == "P+S" || thisSym == "S+P") {
        double yCoorPos = qAbs(yCoor + spacingInLoop);
        double yCoorNeg = -qAbs(yCoor + spacingInLoop);

        // Draw right line (S side)
        firstPoint_y = centerX + static_cast<int>(yCoorPos / 1000.0 * spacing);
        firstPoint_z = centerY - -99999 * spacing;
        secondPoint_y = centerX + static_cast<int>(yCoorPos / 1000.0 * spacing);
        secondPoint_z = centerY - 99999 * spacing;
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
    qDebug() << "Drew P+S right vertical line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
    m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), false, index, (yCoorPos), QStringLiteral("Z") });

        // Draw left line (P side)
        firstPoint_y = centerX + static_cast<int>(yCoorNeg / 1000.0 * spacing);
        firstPoint_z = centerY - -99999 * spacing;
        secondPoint_y = centerX + static_cast<int>(yCoorNeg / 1000.0 * spacing);
        secondPoint_z = centerY - 99999 * spacing;
        p->drawLine(firstPoint_y, firstPoint_z, secondPoint_y, secondPoint_z);
        qDebug() << "Drew P+S left vertical line from (" << firstPoint_y << "," << firstPoint_z << ") to (" << secondPoint_y << "," << secondPoint_z << ")";
        m_drawnLines.push_back({ QLineF(QPointF(firstPoint_y, firstPoint_z), QPointF(secondPoint_y, secondPoint_z)), false, index, (yCoorNeg), QStringLiteral("Z") });
    }
}

// Validation and calculation helper functions
bool FrameArrangementYZFrameController::isValidFieldData(const QJsonObject& fieldData) const
{
    bool hasNo = fieldData.contains("no");
    bool hasYorZ = fieldData.contains("y") || fieldData.contains("z");
    bool hasSpacing = fieldData.contains("spacing");
    bool hasSym = fieldData.contains("sym");
    
    qDebug() << "Validation - hasNo:" << hasNo << "hasYorZ:" << hasYorZ 
             << "hasSpacing:" << hasSpacing << "hasSym:" << hasSym;
    qDebug() << "Field data keys:" << fieldData.keys();
    
    return hasNo && hasYorZ && hasSpacing && hasSym;
}

int FrameArrangementYZFrameController::calculateLineCount(const QJsonObject& fieldData) const
{
    if (!fieldData.contains("no")) return 0;
    return qMax(0, fieldData.value("no").toInt());
}

double FrameArrangementYZFrameController::calculateLineSpacing(const QJsonObject& fieldData) const
{
    if (!fieldData.contains("spacing")) return 0.0;
    return fieldData.value("spacing").toDouble();
}

QList<double> FrameArrangementYZFrameController::calculateLinePositions(double startValue, int lineCount, double spacing) const
{
    QList<double> positions;
    if (lineCount <= 0) return positions;

    if (lineCount == 1) {
        positions.append(startValue);
    } else {
        for (int i = 0; i < lineCount; ++i) {
            positions.append(startValue + i * spacing);
        }
    }
    return positions;
}

bool FrameArrangementYZFrameController::hasYValue(const QJsonObject& fieldData) const
{
    if (!fieldData.contains("y")) return false;
    
    // Check if Y field is set and not empty string
    QJsonValue yValue = fieldData.value("y");
    if (yValue.isString()) {
        QString yStr = yValue.toString();
        bool isEmpty = yStr.isEmpty();
        qDebug() << "Y value check - string:" << yStr << "isEmpty:" << isEmpty;
        return !isEmpty; // Return true if not empty string (including "0")
    } else if (yValue.isDouble() || yValue.isNull()) {
        // For numeric values, always return true (including 0.0)
        qDebug() << "Y value check - numeric:" << yValue.toDouble() << "- returning true";
        return true;
    }
    
    return false;
}

bool FrameArrangementYZFrameController::hasZValue(const QJsonObject& fieldData) const
{
    if (!fieldData.contains("z")) return false;
    
    // Check if Z field is set and not empty string
    QJsonValue zValue = fieldData.value("z");
    if (zValue.isString()) {
        QString zStr = zValue.toString();
        bool isEmpty = zStr.isEmpty();
        qDebug() << "Z value check - string:" << zStr << "isEmpty:" << isEmpty;
        return !isEmpty; // Return true if not empty string (including "0")
    } else if (zValue.isDouble() || zValue.isNull()) {
        // For numeric values, always return true (including 0.0)
        qDebug() << "Z value check - numeric:" << zValue.toDouble() << "- returning true";
        return true;
    }
    
    return false;
}

void FrameArrangementYZFrameController::loadFrameData()
{
    if (!m_controller) return;

    // Get all frame YZ data from main table
    QMetaObject::invokeMethod(m_controller, "getFrameYZAll", Qt::DirectConnection);
    
    // Get the frameYZList property (contains all data)
    QVariant allData = m_controller->property("frameYZList");
    if (allData.canConvert<QJsonArray>()) {
        m_frameYZDrawing = allData.toJsonArray();
    }
}

QList<QJsonObject> FrameArrangementYZFrameController::getFrameDataForCurrentFrame() const
{
    QList<QJsonObject> currentFrameData;
    
    if (m_currentFrameNo < 0) return currentFrameData;

    // Filter data from m_frameYZDrawing (which now contains all YZ data)
    for (auto val : m_frameYZDrawing) {
        if (!val.isObject()) continue;
        QJsonObject obj = val.toObject();
        int frameNo = obj.value("frameNo").toInt(); // Note: property name might be "frameNo" instead of "frame_no"
        if (frameNo == m_currentFrameNo) {
            currentFrameData.append(obj);
        }
    }

    return currentFrameData;
}

// Property setters
void FrameArrangementYZFrameController::setGridSpacing(int spacing)
{
    if (m_gridSpacing != spacing) {
        m_gridSpacing = spacing;
        emit gridSpacingChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setCurrentFrameNo(int frameNo)
{
    if (m_currentFrameNo != frameNo) {
        m_currentFrameNo = frameNo;
        emit currentFrameNoChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setFrameController(QObject* controller)
{
    if (m_controller != controller) {
        m_controller = controller;
        emit frameControllerChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setGreenLineColor(const QColor& color)
{
    if (m_greenLineColor != color) {
        m_greenLineColor = color;
        emit greenLineColorChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setScaleFactor(double s)
{
    // Clamp scale to reasonable bounds
    double clamped = std::max(0.2, std::min(5.0, s));
    if (!qFuzzyCompare(m_scaleFactor, clamped)) {
        m_scaleFactor = clamped;
        emit scaleFactorChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setPanX(double x)
{
    if (!qFuzzyCompare(m_panX, x)) {
        m_panX = x;
        emit panXChanged();
        update();
    }
}

void FrameArrangementYZFrameController::setPanY(double y)
{
    if (!qFuzzyCompare(m_panY, y)) {
        m_panY = y;
        emit panYChanged();
        update();
    }
}

void FrameArrangementYZFrameController::regenerateDrawingData()
{
    if (!m_controller) return;

    // Simply refresh data from main table
    QMetaObject::invokeMethod(m_controller, "getFrameYZAll", Qt::DirectConnection);
    
    // Refresh the display
    update();
}

// Geometry helpers
double FrameArrangementYZFrameController::distancePointToSegment(const QPointF &pt, const QLineF &seg) const
{
    // Compute the perpendicular distance from pt to segment seg
    const QPointF v = seg.p2() - seg.p1();
    const QPointF w = pt - seg.p1();
    const double c1 = QPointF::dotProduct(w, v);
    if (c1 <= 0) return QLineF(pt, seg.p1()).length();
    const double c2 = QPointF::dotProduct(v, v);
    if (c2 <= c1) return QLineF(pt, seg.p2()).length();
    const double b = c1 / c2;
    const QPointF pb = seg.p1() + b * v;
    return QLineF(pt, pb).length();
}

QPointF FrameArrangementYZFrameController::toWorldFromScreen(const QPointF &screenPt, int centerX, int centerY) const
{
    // Inverse of: translate(pan) -> translate(center) -> scale -> translate(-center)
    // Apply reverse order: translate(+center) then unscale then translate(-center) then un-pan
    QPointF pt = screenPt;
    // Remove pan
    pt -= QPointF(m_panX, m_panY);
    // Move to scaled space origin
    pt -= QPointF(centerX, centerY);
    // Unscale
    if (!qFuzzyIsNull(m_scaleFactor)) pt /= m_scaleFactor;
    // Move back from origin to item coords
    pt += QPointF(centerX, centerY);
    return pt;
}

QVariantMap FrameArrangementYZFrameController::hitTestAt(qreal x, qreal y, qreal pixelTolerance) const
{
    QVariantMap res;
    res["success"] = false;
    if (m_drawnLines.isEmpty()) return res;

    const int w = static_cast<int>(width());
    const int h = static_cast<int>(height());
    const int centerX = w / 2;
    const int centerY = h / 2;
    const QPointF worldPt = toWorldFromScreen(QPointF(x, y), centerX, centerY);

    // Because lines are scaled with painter, distance in world must account for scale.
    // Convert pixelTolerance to world units by dividing by scaleFactor.
    const double tolWorld = pixelTolerance / (qFuzzyIsNull(m_scaleFactor) ? 1.0 : m_scaleFactor);

    double bestDist = std::numeric_limits<double>::infinity();
    int bestIdx = -1;
    for (int i = 0; i < m_drawnLines.size(); ++i) {
        const auto &rec = m_drawnLines[i];
        double d = distancePointToSegment(worldPt, rec.line);
        if (d < bestDist) {
            bestDist = d;
            bestIdx = i;
        }
    }

    if (bestIdx >= 0 && bestDist <= tolWorld) {
        const auto &rec = m_drawnLines[bestIdx];
        res["success"] = true;
        res["index"] = rec.index;
        res["axis"] = rec.axis; // "Y" for horizontal lines, "Z" for vertical lines per spec
        res["valueMM"] = rec.valueMM;
        // Compose label text as requested
        if (rec.horizontal) {
            // Horizontal: "Line L{index} coordinate Y: {nilaiY} Z: ~"
            res["text"] = QString("Line L%1 coordinate Y: ~ Z: %2").arg(rec.index).arg(rec.valueMM);
        } else {
            // Vertical: "Line L{index} coordinate Y: ~ Z: {nilaiZ}"
            res["text"] = QString("Line L%1 coordinate Y: %2 Z: ~").arg(rec.index).arg(rec.valueMM);
        }
    }
    return res;
}
