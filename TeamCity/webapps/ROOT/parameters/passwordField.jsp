<%@include file="/include-internal.jsp"%>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterRenderContext"/>
<jsp:useBean id="publicKey" scope="request" type="java.lang.String"/>
<jsp:useBean id="value" scope="request" type="java.lang.String"/>

<forms:passwordField disabled="${context.readOnly}" name="${context.id}" id="${context.id}" encryptedPassword="${value}" publicKey="${publicKey}" style="width:100%"/>

<ext:registerTypedParameterScript context="${context}">
{
  getControlValue: function() {
    return $('${context.id}').getEncryptedPassword();
  }
}
</ext:registerTypedParameterScript>

