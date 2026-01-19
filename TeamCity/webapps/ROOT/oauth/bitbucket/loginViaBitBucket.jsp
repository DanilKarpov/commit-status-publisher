<%@ page import="jetbrains.buildServer.serverSide.oauth.bitbucket.BitBucketAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=BitBucketAuthentication.LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with BitBucket"><span class="loginIcon_bitbucket"/></a>
