<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="forceClose" scope="request" type="java.lang.Boolean"/>

<c:set var="styles">
  <bs:linkCSS>
    /css/forms.css
  </bs:linkCSS>
  <style type="text/css">
    div.appCreated {
      margin: 25%;
      font-size: 120%;
    }
  </style>
</c:set>

<bs:externalPage>
  <jsp:attribute name="page_title">Space Integration</jsp:attribute>
  <jsp:attribute name="head_include">

    ${styles}
    <script type="text/javascript">
      {
        const forceClose = ${forceClose};
        if (forceClose || (window.opener && window.opener !== window)) {
          window.close();
        }
      }
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
        <div class="appCreated">
          Space application has been created. Please close this window.
        </div>
  </jsp:attribute>
</bs:externalPage>