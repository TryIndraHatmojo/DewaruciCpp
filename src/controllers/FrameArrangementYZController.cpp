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

void FrameArrangementYZController::setModel(FrameArrangementYZ* model) {
	m_model = model;
}

static QJsonArray toJsonArray(const QVariantList &list) {
	QJsonArray array;
	for (const QVariant &v : list) {
		array.append(QJsonObject::fromVariantMap(v.toMap()));
	}
	return array;
}

QJsonArray FrameArrangementYZController::generateObjectJson(const QVariantList &data) {
	return toJsonArray(data);
}

int FrameArrangementYZController::insertFrameYZ(const QString &name, int no, double spacing,
													double y, double z, int frameNo, const QString &fa, const QString &sym) {
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
												 double y, double z, int frameNo, const QString &fa, const QString &sym) {
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

