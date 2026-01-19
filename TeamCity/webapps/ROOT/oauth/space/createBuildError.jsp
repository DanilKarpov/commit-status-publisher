<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="errorMessage" scope="request" type="java.lang.String"/>

<bs:externalPage>
  <jsp:attribute name="page_title">Create build from Space repository</jsp:attribute>
  <jsp:attribute name="head_include">
    <style type="text/css">
      div.mainContent {
        padding: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="mainContent">
      <h2>Space Create Build Error</h2>
      <p>${errorMessage}</p>
    </div>
  </jsp:attribute>
</bs:externalPage>