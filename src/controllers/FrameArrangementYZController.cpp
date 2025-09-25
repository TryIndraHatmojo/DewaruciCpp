#include "FrameArrangementYZController.h"
#include "../database/models/FrameArrangementYZ.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

FrameArrangementYZController::FrameArrangementYZController(QObject* parent)
	: QObject(parent), m_model(nullptr) {}

void FrameArrangementYZController::setFrameYZList(const QJsonArray &list) {
	if (m_frameYZList != list) {
		m_frameYZList = list;
		emit frameYZListChanged();
	}
}

void FrameArrangementYZController::setSelectedFrameYZ(const QJsonArray &list) {
	if (m_selectedFrameYZ != list) {
		m_selectedFrameYZ = list;
		emit selectedFrameYZChanged();
	}
}

void FrameArrangementYZController::setSelectedFrameYZId(const QJsonArray &list) {
	if (m_selectedFrameYZId != list) {
		m_selectedFrameYZId = list;
		emit selectedFrameYZIdChanged();
	}
}

void FrameArrangementYZController::setSelectedFrameYZName(const QJsonArray &list) {
	if (m_selectedFrameYZName != list) {
		m_selectedFrameYZName = list;
		emit selectedFrameYZNameChanged();
	}
}

void FrameArrangementYZController::setFrameYZDrawing(const QJsonArray &list) {
	if (m_frameYZDrawing != list) {
		m_frameYZDrawing = list;
		emit frameYZDrawingChanged();
	}
}

void FrameArrangementYZController::setModel(FrameArrangementYZ* model) {
	m_model = model;
}

static QJsonArray toJsonArray(const QVariantList &list) {
	QJsonArray array;
	for (const QVariant &v : list) {
		QVariantMap m = v.toMap();
		QJsonObject o = QJsonObject::fromVariantMap(m);
		// Ensure y/z keep string empties if provided by model
		if (m.contains("y")) {
			QVariant yv = m.value("y");
			if (yv.typeId() == QMetaType::QString) {
				o.insert("y", yv.toString());
			}
		}
		if (m.contains("z")) {
			QVariant zv = m.value("z");
			if (zv.typeId() == QMetaType::QString) {
				o.insert("z", zv.toString());
			}
		}
		array.append(o);
	}
	return array;
}

QJsonArray FrameArrangementYZController::generateObjectJson(const QVariantList &data) {
	return toJsonArray(data);
}

int FrameArrangementYZController::insertFrameYZ(const QString &name, int no, double spacing,
													const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym) {
	if (!m_model) { emit errorOccurred("Model not set"); return -1; }
	int lastId = m_model->insertFrame(name, no, spacing, y, z, frameNo, fa, sym);
	// Reload full list after insert
	getFrameYZAll();
	return lastId;
}

void FrameArrangementYZController::getFrameYZByFrameNo(int frameNumber) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (!m_model->loadDataByFrameNo(frameNumber)) { return; }
	// Build selected list from model rows
	QVariantList rows;
	for (int i = 0; i < m_model->getRowCount(); ++i) rows.append(m_model->getFrameAtIndex(i));
	setSelectedFrameYZ(generateObjectJson(rows));
}

void FrameArrangementYZController::deleteFrameYZ(int id) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (m_model->deleteFrame(id)) {
		getFrameYZAll();
	}
}

void FrameArrangementYZController::updateFrameYZ(int id, const QString &name, int no, double spacing,
												 const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (m_model->updateFrame(id, name, no, spacing, y, z, frameNo, fa, sym)) {
		getFrameYZAll();
	}
}

void FrameArrangementYZController::updateFrameYZFa(int id, const QString &fa) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (m_model->updateFrameFa(id, fa)) {
		// Python emits frame_arrangement_yz_changed; here we can refresh list or leave to UI
		getFrameYZAll();
	}
}

void FrameArrangementYZController::updateFrameYZSym(int id, const QString &sym) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (m_model->updateFrameSym(id, sym)) {
		getFrameYZAll();
	}
}

void FrameArrangementYZController::deleteFrameYZByFrameNumber(int frameNo) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (m_model->deleteFramesByFrameNumber(frameNo)) {
		// Keep current list refreshed
		getFrameYZAll();
	}
}

void FrameArrangementYZController::getFrameYZAll() {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	if (!m_model->loadData()) { return; }
	QVariantList rows;
	for (int i = 0; i < m_model->getRowCount(); ++i) rows.append(m_model->getFrameAtIndex(i));
	// Do not auto-overwrite names here: respect manual entries; rows already reflect DB
	setFrameYZList(generateObjectJson(rows));
}

void FrameArrangementYZController::getFrameYZById(int id) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	QVariantMap row = m_model->getFrameById(id);
	QVariantList list;
	if (!row.isEmpty()) list.append(row);
	setSelectedFrameYZId(generateObjectJson(list));
}

void FrameArrangementYZController::getFrameYZByName(const QString &name) {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	QVariantList rows = m_model->getFramesByName(name);
	setSelectedFrameYZName(generateObjectJson(rows));
}

void FrameArrangementYZController::recomputeNames() {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	// Use current list if available; otherwise fetch all
	QVariantList rows;
	for (int i = 0; i < m_model->getRowCount(); ++i) rows.append(m_model->getFrameAtIndex(i));
	if (rows.isEmpty()) {
		if (!m_model->loadData()) return;
		for (int i = 0; i < m_model->getRowCount(); ++i) rows.append(m_model->getFrameAtIndex(i));
	}
	// Intentionally skip recompute to avoid overwriting manual names; left here for future use if needed.
	// Emit fresh list
	rows.clear();
	for (int i = 0; i < m_model->getRowCount(); ++i) rows.append(m_model->getFrameAtIndex(i));
	setFrameYZList(generateObjectJson(rows));
}

QJsonArray FrameArrangementYZController::checkSuffixConflict(const QString &prefix, int startSuffix, int count) {
	if (!m_model) { emit errorOccurred("Model not set"); return QJsonArray(); }
	QVariantList v = m_model->checkSuffixConflict(prefix, startSuffix, count);
	return generateObjectJson(v);
}

int FrameArrangementYZController::getLastSuffixForPrefix(const QString &prefix) {
	if (!m_model) { emit errorOccurred("Model not set"); return -1; }
	return m_model->getLastSuffixForPrefix(prefix);
}

bool FrameArrangementYZController::assignManualNames(int id, const QString &prefix, int startSuffix, int count) {
	if (!m_model) { emit errorOccurred("Model not set"); return false; }
	bool ok = m_model->assignManualNames(id, prefix, startSuffix, count);
	if (ok) getFrameYZAll();
	return ok;
}

bool FrameArrangementYZController::assignAutoNamesFrom(int id, const QString &prefix, int continueFromSuffix, int count) {
	if (!m_model) { emit errorOccurred("Model not set"); return false; }
	bool ok = m_model->assignAutoNamesFrom(id, prefix, continueFromSuffix, count);
	if (ok) getFrameYZAll();
	return ok;
}

bool FrameArrangementYZController::updateFrameIsManual(int id, bool isManual) {
	if (!m_model) { emit errorOccurred("Model not set"); return false; }
	bool ok = m_model->updateFrameIsManual(id, isManual);
	if (ok) getFrameYZAll();
	return ok;
}

void FrameArrangementYZController::computeAndPersistNames(const QVariantList &rows) {
	if (!m_model) return;

	// Strategy: per-prefix 0-based numbering after sorting by prefix.
	// 1) Build a temp list of {id, prefix} and sort by prefix (A→Z), then by id for stability.
	struct Item { int id; QString prefix; };
	QVector<Item> items;
	items.reserve(rows.size());
	for (const QVariant &v : rows) {
		const QVariantMap m = v.toMap();
		const int id = m.value("id").toInt();
		const QString name = m.value("name").toString();
		QString prefix;
		for (int k = 0; k < name.size(); ++k) { const QChar ch = name.at(k); if (ch.isLetter()) prefix.append(ch.toUpper()); else break; }
		if (prefix.isEmpty()) prefix = QStringLiteral("L");
		items.push_back({ id, prefix });
	}
	std::sort(items.begin(), items.end(), [](const Item &a, const Item &b){
		if (a.prefix == b.prefix) return a.id < b.id; // stable ordering within prefix
		return a.prefix < b.prefix;
	});

	// 2) Assign names: for each prefix, suffix starts at 0 and accumulates by previous row's No in that prefix.
	// Build a quick lookup from id to No to compute steps.
	QHash<int,int> idToNo;
	for (const QVariant &v : rows) {
		const QVariantMap m = v.toMap();
		idToNo.insert(m.value("id").toInt(), m.value("no").toInt());
	}

	QHash<QString, long long> counters; // suffix per prefix
	for (const Item &it : items) {
		long long suffix = counters.value(it.prefix, 0);
		const QString expectedName = it.prefix + QString::number(suffix);
		m_model->updateFrameName(it.id, expectedName, /*reloadModel*/ false);
		long long step = static_cast<long long>(qMax(1, idToNo.value(it.id, 0)));
		counters.insert(it.prefix, suffix + step);
	}

	// One reload at the end to reflect all updates (model will also sort and renumber consistently)
	m_model->loadData();
}

// ---------------- Frame YZ Drawing (mirrors Python functions) ----------------
int FrameArrangementYZController::insertFrameYZDrawing(int frameyzId, const QString &name, int no, double spacing,
													 double y, double z, int frameNo, const QString &fa, const QString &sym) {
	if (!m_model) { emit errorOccurred("Model not set"); return -1; }
	// Ensure drawing table exists
	m_model->createDrawingTable();
	int id = m_model->insertFrameYZDrawing(frameyzId, name, no, spacing, y, z, frameNo, fa, sym);
	emit frameArrangementYZDrawingChanged();
	return id;
}

bool FrameArrangementYZController::resetFrameYZDrawing() {
	if (!m_model) { emit errorOccurred("Model not set"); return false; }
	bool ok = m_model->resetFrameYZDrawingTable();
	if (ok) emit frameArrangementYZDrawingChanged();
	return ok;
}

void FrameArrangementYZController::getAllFrameYZDrawing() {
	if (!m_model) { emit errorOccurred("Model not set"); return; }
	QVariantList list = m_model->getAllFrameYZDrawing();
	setFrameYZDrawing(generateObjectJson(list));
	emit frameArrangementYZDrawingChanged();
}

