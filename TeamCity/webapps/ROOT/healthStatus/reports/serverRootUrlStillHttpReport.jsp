<%@ include file="/include-internal.jsp" %>

You have configured the HTTPS access, but the server URL is still using HTTP. To ensure redirects, cloud agents, and notifications function correctly, go to <a href="<c:url value="/admin/admin.html?item=serverConfigGeneral"/>">global settings</a> and change the server URL to HTTPS.