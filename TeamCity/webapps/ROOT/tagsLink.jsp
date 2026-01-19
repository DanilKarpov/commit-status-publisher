<%@ include file="../include-internal.jsp"
%><%@ taglib prefix="bs" tagdir="/WEB-INF/tags"
%><%@ taglib prefix="t" tagdir="/WEB-INF/tags/tags"
%><jsp:useBean id="buildPromotion" scope="request" type="jetbrains.buildServer.serverSide.BuildPromotion"
/><t:tagsInfoInner buildPromotion="${buildPromotion}" tags="${buildPromotion.tags}" compactView="${compactView}"/>