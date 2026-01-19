<%@include file="/include-internal.jsp"%>
<jsp:useBean id="editGroupBean" type="jetbrains.buildServer.controllers.admin.groups.EditGroupBean" scope="request"/>
<c:set var="notifiersBean" value="${editGroupBean.notifiersBean}"/>
<c:set var="selectedNotifier" value="${param['notificatorType']}"/>
<c:if test="${empty selectedNotifier}">
  <c:set var="selectedNotifier"><%=editGroupBean.getNotifiersBean().getAvailableNotifiers().get(0).getNotificatorType()%></c:set>
</c:if>

<c:url value='/admin/editGroup.html' var="url">
  <c:param name="groupCode" value="${editGroupBean.group.key}"/>
  <c:param name="tab" value="groupNotifications"/>
  <c:param name="adminMode" value="true"/>
  <c:param name="init" value="1"/>
</c:url>
<n:availableNotifiers urlPattern="${url}&notificatorType=##notifierType##"
                        selectedNotifier="${selectedNotifier}"
                        availableNotifiersBean="${notifiersBean}"/>

<div id="notificationRulesPage">
<jsp:include page="/notificationRules.html?notificatorType=${selectedNotifier}&holderId=group:${editGroupBean.group.key}"/>
</div>
