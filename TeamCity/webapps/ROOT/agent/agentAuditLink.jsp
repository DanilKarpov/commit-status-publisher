<%@ page import="jetbrains.buildServer.serverSide.impl.audit.ActionTypeSet" %>
<%@ include file="/include-internal.jsp" %>
<%--@elvariable id="lastAuditAction" type="jetbrains.buildServer.serverSide.audit.AuditLogAction"--%>
<c:if test="${lastAuditAction != null}">
  <c:set var="subjectTypeId" value="${lastAuditAction.subjectType.id}"/>
  <c:set var="actionTypeSetId" value="<%=ActionTypeSet.ALL_FOR_AGENT.getId()%>"/>

  <div>
    <a href="<c:url value="/admin/admin.html?item=audit&actionTypeSet=${actionTypeSetId}&objectId=${objectId}&subjectType=${subjectTypeId}&subjectId=${subjectId}"/>" target="_blank" rel="noreferrer">
      View audit log
    </a>
    (last action <bs:date value="${lastAuditAction.timestamp}" smart="true" no_smart_title="true"/> by <admin:auditLogActionUserName auditLogAction="${lastAuditAction}"/>)
  </div>
</c:if>
