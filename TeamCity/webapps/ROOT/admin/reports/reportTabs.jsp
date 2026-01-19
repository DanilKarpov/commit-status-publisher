<%@include file="/include-internal.jsp"%>
<jsp:useBean id="reportTabsForm" type="jetbrains.buildServer.controllers.admin.reportTabs.EditReportTabsForm" scope="request"/>

<div>
  <admin:editReportTabDialog title="Edit Report Tab Settings" project="${reportTabsForm.project}" reportTabsForm="${reportTabsForm}"/>
  <%--@elvariable id="pageUrl" type="java.lang.String"--%>
  <admin:editReportTabsTable pageUrl="${pageUrl}" reportTabsForm="${reportTabsForm}" project="${reportTabsForm.project}"/>
</div>
