<%@ page import="jetbrains.buildServer.serverSide.oauth.space.SpaceAuthentication" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>
<c:url var="path" value="<%=SpaceAuthentication.SPACE_LOGIN_CONTROLLER_PATH%>"/>
<a href="${path}" title="Log in with Space"><span class="loginIcon_space"/></a>
